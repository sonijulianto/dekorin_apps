import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:dekorin_apps/data/datasources/local/data_preferences.dart';
import 'package:dekorin_apps/data/datasources/remote/api_endpoint.dart';
import 'package:dekorin_apps/data/datasources/remote/image_compressor.dart';
import 'package:dekorin_apps/data/datasources/remote/network_error_helper.dart';
import 'package:dekorin_apps/data/services/error_log_service.dart';
import 'package:dekorin_apps/domain/models/picked_image_data.dart';

/// Exception khusus yang membawa pesan error dari API.
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// HTTP Client terpusat untuk seluruh aplikasi (Mobile & Web).
///
/// Menangani:
/// - Base URL otomatis dari [ApiEndpoint]
/// - Header `Content-Type` & `Authorization` (Bearer token) otomatis
/// - Parsing JSON response
/// - Error handling terpusat (network error & API error)
class ApiClient {
  ApiClient._();

  /// Timeout default untuk semua HTTP request.
  static const _timeout = Duration(seconds: 15);

  /// Callback global yang dipanggil saat token kadaluarsa atau tidak valid (HTTP 401)
  static void Function()? onUnauthorized;
  static bool _isHandlingUnauthorized = false;

  static void _triggerUnauthorized() {
    if (_isHandlingUnauthorized) return;
    _isHandlingUnauthorized = true;

    DataPreferences.logout();

    try {
      onUnauthorized?.call();
    } catch (_) {}

    Future.delayed(const Duration(seconds: 2), () {
      _isHandlingUnauthorized = false;
    });
  }

  static Map<String, String> _headers({bool withToken = true}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    if (withToken) {
      final token = DataPreferences.getToken();
      if (token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  static dynamic _handleResponse(
    http.Response response, {
    String method = 'HTTP',
    String endpoint = '',
  }) {
    if (endpoint.isNotEmpty && endpoint != ApiEndpoint.clientLogs) {
      ErrorLogService.instance.addBreadcrumb('api', '$method $endpoint -> ${response.statusCode}');
    }

    if (response.statusCode >= 500 && endpoint != ApiEndpoint.clientLogs) {
      unawaited(
        ErrorLogService.instance.reportError(
          ApiException('HTTP ${response.statusCode} on $method $endpoint', statusCode: response.statusCode),
          StackTrace.current,
          level: 'error',
          apiContext: {
            'method': method,
            'endpoint': endpoint,
            'status_code': response.statusCode,
            'response_snippet': response.body,
          },
        ),
      );
    }

    dynamic body;
    try {
      body = jsonDecode(response.body);
    } catch (_) {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response.body;
      }
      if (response.statusCode == 401) {
        _triggerUnauthorized();
      }
      if (response.statusCode == 413) {
        throw ApiException(
          'Ukuran file terlalu besar melebihi kapasitas server (413 Payload Too Large).',
          statusCode: 413,
        );
      }
      throw ApiException(
        response.body.isNotEmpty
            ? response.body
            : 'Terjadi kesalahan pada server (${response.statusCode}).',
        statusCode: response.statusCode,
      );
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    if (response.statusCode == 401) {
      _triggerUnauthorized();
    }
    if (response.statusCode == 413) {
      throw ApiException(
        'Ukuran file terlalu besar melebihi kapasitas server (413 Payload Too Large).',
        statusCode: 413,
      );
    }

    String errorMessage = 'Terjadi kesalahan pada server.';
    if (body is Map) {
      errorMessage = body['error'] ?? body['message'] ?? errorMessage;
    }
    throw ApiException(errorMessage, statusCode: response.statusCode);
  }

  static Future<dynamic> _executeRequest(
    Future<http.Response> Function() requestFn, {
    String method = 'HTTP',
    String endpoint = '',
    Duration? timeout,
    String? timeoutMessage,
  }) async {
    final effectiveTimeout = timeout ?? _timeout;
    try {
      final response = await requestFn().timeout(effectiveTimeout);
      return _handleResponse(response, method: method, endpoint: endpoint);
    } on TimeoutException catch (e, stack) {
      if (endpoint != ApiEndpoint.clientLogs) {
        ErrorLogService.instance.addBreadcrumb('api', '$method $endpoint -> TIMEOUT');
        unawaited(
          ErrorLogService.instance.reportError(
            e,
            stack,
            level: 'warning',
            apiContext: {'method': method, 'endpoint': endpoint, 'timeout_sec': effectiveTimeout.inSeconds},
          ),
        );
      }
      throw ApiException(
        timeoutMessage ??
            'Server tidak merespons (timeout ${effectiveTimeout.inSeconds} detik). Pastikan server berjalan dan URL benar.',
      );
    } on ApiException {
      rethrow;
    } catch (e, stack) {
      if (isNetworkConnectionError(e)) {
        throw ApiException('Gagal terhubung ke server. Periksa koneksi internet Anda.');
      }
      if (endpoint != ApiEndpoint.clientLogs) {
        unawaited(
          ErrorLogService.instance.reportError(
            e,
            stack,
            level: 'error',
            apiContext: {'method': method, 'endpoint': endpoint},
          ),
        );
      }
      throw ApiException('Terjadi kesalahan: $e');
    }
  }

  // ── GET ───────────────────────────────────────────────────
  static Future<dynamic> get(String endpoint, {bool withToken = true}) {
    return _executeRequest(
      () => http.get(
        Uri.parse('${ApiEndpoint.baseUrl}$endpoint'),
        headers: _headers(withToken: withToken),
      ),
      method: 'GET',
      endpoint: endpoint,
    );
  }

  // ── POST ──────────────────────────────────────────────────
  static Future<dynamic> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool withToken = true,
    Duration? timeout,
  }) {
    final effectiveTimeout = timeout ?? _timeout;
    return _executeRequest(
      () => http.post(
        Uri.parse('${ApiEndpoint.baseUrl}$endpoint'),
        headers: _headers(withToken: withToken),
        body: body != null ? jsonEncode(body) : null,
      ),
      method: 'POST',
      endpoint: endpoint,
      timeout: effectiveTimeout,
      timeoutMessage:
          'Server tidak merespons (timeout ${effectiveTimeout.inSeconds} detik). Pastikan koneksi internet stabil.',
    );
  }

  // ── PUT ───────────────────────────────────────────────────
  static Future<dynamic> put(
    String endpoint, {
    Map<String, dynamic>? body,
    bool withToken = true,
  }) {
    return _executeRequest(
      () => http.put(
        Uri.parse('${ApiEndpoint.baseUrl}$endpoint'),
        headers: _headers(withToken: withToken),
        body: body != null ? jsonEncode(body) : null,
      ),
      method: 'PUT',
      endpoint: endpoint,
    );
  }

  // ── PATCH ──────────────────────────────────────────────────
  static Future<dynamic> patch(
    String endpoint, {
    Map<String, dynamic>? body,
    bool withToken = true,
  }) {
    return _executeRequest(
      () => http.patch(
        Uri.parse('${ApiEndpoint.baseUrl}$endpoint'),
        headers: _headers(withToken: withToken),
        body: body != null ? jsonEncode(body) : null,
      ),
      method: 'PATCH',
      endpoint: endpoint,
    );
  }

  // ── DELETE ────────────────────────────────────────────────
  static Future<dynamic> delete(String endpoint, {bool withToken = true}) {
    return _executeRequest(
      () => http.delete(
        Uri.parse('${ApiEndpoint.baseUrl}$endpoint'),
        headers: _headers(withToken: withToken),
      ),
      method: 'DELETE',
      endpoint: endpoint,
    );
  }

  // ── UPLOAD IMAGE ──────────────────────────────────────────
  static Future<String> uploadImage(
    PickedImageData image, {
    bool withToken = true,
  }) async {
    final body = await uploadMultipart(
      '/upload',
      fileField: 'image',
      image: image,
      withToken: withToken,
      timeout: const Duration(seconds: 45),
      timeoutMessage: 'Gagal mengunggah gambar (timeout). Periksa koneksi internet Anda.',
    );
    return body['url'] as String? ?? '';
  }

  // ── UPLOAD MULTIPART GENERIC ──────────────────────────────
  static Future<dynamic> uploadMultipart(
    String endpoint, {
    required String fileField,
    required PickedImageData image,
    Map<String, String>? fields,
    bool withToken = true,
    Duration timeout = const Duration(seconds: 45),
    String? timeoutMessage,
  }) async {
    try {
      final processedImage = await ImageCompressor.compressUnder5MB(image);

      final uri = Uri.parse('${ApiEndpoint.baseUrl}$endpoint');
      final request = http.MultipartRequest('POST', uri);

      if (withToken) {
        final token = DataPreferences.getToken();
        if (token.isNotEmpty) {
          request.headers['Authorization'] = 'Bearer $token';
        }
      }

      if (fields != null) {
        request.fields.addAll(fields);
      }

      final multipartFile = http.MultipartFile.fromBytes(
        fileField,
        processedImage.bytes,
        filename: processedImage.filename,
      );
      request.files.add(multipartFile);

      final streamedResponse = await request.send().timeout(timeout);
      final response = await http.Response.fromStream(streamedResponse).timeout(timeout);
      return _handleResponse(response);
    } on TimeoutException {
      throw ApiException(
        timeoutMessage ??
            'Proses analisis AI membutuhkan waktu lebih lama. Silakan periksa koneksi Anda.',
      );
    } on ApiException {
      rethrow;
    } catch (e) {
      if (isNetworkConnectionError(e)) {
        throw ApiException('Gagal terhubung ke server. Periksa koneksi internet Anda.');
      }
      throw ApiException('Gagal memproses file: $e');
    }
  }
}
