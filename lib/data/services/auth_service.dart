import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import 'package:dekorin_apps/data/datasources/local/data_preferences.dart';
import 'package:dekorin_apps/data/models/user_model.dart';

/// Provider for AuthService
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Service that handles real authentication API calls to Golang backend.
class AuthService {
  // http://10.0.2.2:3000/api untuk Android Emulator, atau 127.0.0.1 untuk iOS/Web/Mac
  static const String _baseUrl = 'http://10.166.190.239:3000/api';

  /// Attempts to authenticate with the given [email] and [password].
  ///
  /// Returns a [UserModel] on success and saves token & user to local storage.
  /// Throws an [Exception] if credentials are invalid or network fails.
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$_baseUrl/auth/login');
    http.Response response;

    // 1. Try-catch khusus untuk error jaringan
    try {
      response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );
    } catch (e) {
      throw Exception('Gagal terhubung ke server. Pastikan API Golang menyala.');
    }

    // 2. Parse response JSON dari backend
    final responseData = jsonDecode(response.body);

    // 3. Tangani HTTP Status Code
    if (response.statusCode == 200) {
      final user = UserModel.fromJson(responseData['data']);
      final token = responseData['token'];

      // Simpan token dan data user ke SharedPreferences via DataPreferences
      await DataPreferences.setToken(token);
      await DataPreferences.setUser(jsonEncode(user.toJson()));

      return user;
    } else {
      final errorMessage = responseData['error'] ?? 'Login gagal.';
      throw Exception(errorMessage);
    }
  }

  /// Cek apakah user sudah login sebelumnya (membaca SharedPreferences)
  Future<UserModel?> getSavedUser() async {
    final userJsonString = DataPreferences.getUser();
    final token = DataPreferences.getToken();

    if (userJsonString != null && token.isNotEmpty) {
      final Map<String, dynamic> userMap = jsonDecode(userJsonString);
      return UserModel.fromJson(userMap);
    }
    return null;
  }

  /// Logout (menghapus token dan data user dari lokal)
  Future<void> logout() async {
    await DataPreferences.logout();
  }
}
