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
    final body = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    } else {
      // Ambil pesan error dari API (jika ada), fallback ke pesan generic
      final errorMessage = body['error'] ?? body['message'] ?? 'Terjadi kesalahan pada server.';
      throw ApiException(errorMessage, statusCode: response.statusCode);
    }
  }

  // ── GET ───────────────────────────────────────────────────
  static Future<dynamic> get(String endpoint, {bool withToken = true}) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiEndpoint.baseUrl}$endpoint'),
        headers: _headers(withToken: withToken),
      );
      return _handleResponse(response);
    } on SocketException {
      throw ApiException('Gagal terhubung ke server. Periksa koneksi internet Anda.');
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
      );
      return _handleResponse(response);
    } on SocketException {
      throw ApiException('Gagal terhubung ke server. Periksa koneksi internet Anda.');
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
      );
      return _handleResponse(response);
    } on SocketException {
      throw ApiException('Gagal terhubung ke server. Periksa koneksi internet Anda.');
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
      );
      return _handleResponse(response);
    } on SocketException {
      throw ApiException('Gagal terhubung ke server. Periksa koneksi internet Anda.');
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Terjadi kesalahan: $e');
    }
  }
}
