import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dekorin_apps/data/datasources/local/data_preferences.dart';
import 'package:dekorin_apps/data/datasources/remote/api_client.dart';
import 'package:dekorin_apps/data/datasources/remote/api_endpoint.dart';
import 'package:dekorin_apps/data/models/user_model.dart';

/// Provider for AuthService
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Service yang menangani autentikasi ke backend Golang.
///
/// Menggunakan [ApiClient] terpusat agar tidak ada boilerplate
/// (base URL, headers, error handling sudah ditangani otomatis).
class AuthService {
  /// Login dengan [email] dan [password].
  ///
  /// Return [UserModel] jika sukses, throw [ApiException] jika gagal.
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final responseData = await ApiClient.post(
      ApiEndpoint.login,
      body: {'email': email, 'password': password},
      withToken: false, // Belum punya token saat login
    );

    final user = UserModel.fromJson(responseData['data']);
    final token = responseData['token'];

    // Simpan token dan data user ke lokal
    await DataPreferences.setToken(token);
    await DataPreferences.setUser(jsonEncode(user.toJson()));

    return user;
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
