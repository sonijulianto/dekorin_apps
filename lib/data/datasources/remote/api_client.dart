import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'package:dekorin_apps/data/datasources/local/data_preferences.dart';
import 'package:dekorin_apps/data/datasources/remote/api_endpoint.dart';

/// Exception khusus yang membawa pesan error dari API.
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

/// HTTP Client terpusat untuk seluruh aplikasi.
///
/// Menangani:
/// - Base URL otomatis dari [ApiEndpoint]
/// - Header `Content-Type` & `Authorization` (Bearer token) otomatis
/// - Parsing JSON response
/// - Error handling terpusat (network error & API error)
///
/// Contoh penggunaan:
/// ```dart
/// final data = await ApiClient.post(ApiEndpoint.login, body: {...});
/// ```
class ApiClient {
  ApiClient._(); // Tidak bisa di-instansiasi

  /// Timeout default untuk semua HTTP request.
  /// Jika server tidak merespons dalam waktu ini, request dibatalkan
  /// dan muncul pesan error (tidak loading selamanya).
  static const _timeout = Duration(seconds: 15);

  // ── Helper: Membuat headers ───────────────────────────────
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

  // ── Helper: Handle response ───────────────────────────────
  static dynamic _handleResponse(http.Response response) {
    dynamic body;
    try {
      body = jsonDecode(response.body);
    } catch (_) {
      // Body bukan format JSON valid (misal: plain text 404 dari Go Fiber / Nginx)
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return response.body;
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
    } else {
      // Ambil pesan error dari API (jika ada), fallback ke pesan generic
      String errorMessage = 'Terjadi kesalahan pada server.';
      if (body is Map) {
        errorMessage = body['error'] ?? body['message'] ?? errorMessage;
      }
      throw ApiException(errorMessage, statusCode: response.statusCode);
    }
  }

  // ── GET ───────────────────────────────────────────────────
  static Future<dynamic> get(String endpoint, {bool withToken = true}) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiEndpoint.baseUrl}$endpoint'),
        headers: _headers(withToken: withToken),
      ).timeout(_timeout);
      return _handleResponse(response);
    } on SocketException {
      throw ApiException('Gagal terhubung ke server. Periksa koneksi internet Anda.');
    } on TimeoutException {
      throw ApiException('Server tidak merespons (timeout 15 detik). Pastikan server berjalan dan URL benar.');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Terjadi kesalahan: $e');
    }
  }

  // ── POST ──────────────────────────────────────────────────
  static Future<dynamic> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool withToken = true,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiEndpoint.baseUrl}$endpoint'),
        headers: _headers(withToken: withToken),
        body: body != null ? jsonEncode(body) : null,
      ).timeout(_timeout);
      return _handleResponse(response);
    } on SocketException {
      throw ApiException('Gagal terhubung ke server. Periksa koneksi internet Anda.');
    } on TimeoutException {
      throw ApiException('Server tidak merespons (timeout 15 detik). Pastikan server berjalan dan URL benar.');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Terjadi kesalahan: $e');
    }
  }

  // ── PUT ───────────────────────────────────────────────────
  static Future<dynamic> put(
    String endpoint, {
    Map<String, dynamic>? body,
    bool withToken = true,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiEndpoint.baseUrl}$endpoint'),
        headers: _headers(withToken: withToken),
        body: body != null ? jsonEncode(body) : null,
      ).timeout(_timeout);
      return _handleResponse(response);
    } on SocketException {
      throw ApiException('Gagal terhubung ke server. Periksa koneksi internet Anda.');
    } on TimeoutException {
      throw ApiException('Server tidak merespons (timeout 15 detik). Pastikan server berjalan dan URL benar.');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Terjadi kesalahan: $e');
    }
  }

  // ── DELETE ────────────────────────────────────────────────
  static Future<dynamic> delete(String endpoint, {bool withToken = true}) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiEndpoint.baseUrl}$endpoint'),
        headers: _headers(withToken: withToken),
      ).timeout(_timeout);
      return _handleResponse(response);
    } on SocketException {
      throw ApiException('Gagal terhubung ke server. Periksa koneksi internet Anda.');
    } on TimeoutException {
      throw ApiException('Server tidak merespons (timeout 15 detik). Pastikan server berjalan dan URL benar.');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Terjadi kesalahan: $e');
    }
  }

  // ── UPLOAD IMAGE ──────────────────────────────────────────
  static Future<String> uploadImage(File file, {bool withToken = true}) async {
    try {
      final uri = Uri.parse('${ApiEndpoint.baseUrl}/upload');
      final request = http.MultipartRequest('POST', uri);

      if (withToken) {
        final token = DataPreferences.getToken();
        if (token.isNotEmpty) {
          request.headers['Authorization'] = 'Bearer $token';
        }
      }

      final multipartFile = await http.MultipartFile.fromPath(
        'image',
        file.path,
      );
      request.files.add(multipartFile);

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final body = _handleResponse(response);

      return body['url'] as String? ?? '';
    } on SocketException {
      throw ApiException('Gagal terhubung ke server. Periksa koneksi internet Anda.');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Gagal mengunggah gambar: $e');
    }
  }
}
