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

/// Service yang menangani autentikasi dan manajemen pengguna ke backend Golang.
class AuthService {
  /// Login dengan [phone] dan [password] (opsional [email] untuk backward compatibility).
  Future<UserModel> login({
    required String phone,
    required String password,
    String? email,
  }) async {
    final responseData = await ApiClient.post(
      ApiEndpoint.login,
      body: {
        'phone': phone,
        'password': password,
        if (email != null && email.isNotEmpty) 'email': email,
      },
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

  /// Mengubah password akun pengguna yang sedang login
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await ApiClient.post(
      ApiEndpoint.changePassword,
      body: {
        'current_password': currentPassword,
        'new_password': newPassword,
      },
    );
  }

  // ── Manajemen Tim / Pengguna ─────────────────────────────────────────

  /// Mengambil daftar semua anggota tim dalam perusahaan
  Future<List<UserModel>> getUsers() async {
    final response = await ApiClient.get(ApiEndpoint.users);
    final List<dynamic> list = response is List ? response : (response['data'] ?? []);
    return list.map((json) => UserModel.fromJson(json as Map<String, dynamic>)).toList();
  }

  /// Membuat akun anggota tim baru (Owner, Admin, atau Crew)
  Future<UserModel> createUser({
    required String fullName,
    required String phone,
    required String password,
    required String role,
    String? email,
  }) async {
    final response = await ApiClient.post(
      ApiEndpoint.users,
      body: {
        'full_name': fullName,
        'phone': phone,
        'password': password,
        'role': role,
        if (email != null && email.isNotEmpty) 'email': email,
      },
    );
    final data = response['data'] ?? response;
    return UserModel.fromJson(data);
  }

  /// Memperbarui akun anggota tim
  Future<UserModel> updateUser({
    required String id,
    String? fullName,
    String? phone,
    String? email,
    String? password,
    String? role,
  }) async {
    final body = <String, dynamic>{};
    if (fullName != null) body['full_name'] = fullName;
    if (phone != null) body['phone'] = phone;
    if (email != null) body['email'] = email;
    if (password != null && password.isNotEmpty) body['password'] = password;
    if (role != null) body['role'] = role;

    final response = await ApiClient.put(
      '${ApiEndpoint.users}/$id',
      body: body,
    );
    final data = response['data'] ?? response;
    return UserModel.fromJson(data);
  }

  /// Menghapus akun anggota tim
  Future<void> deleteUser(String id) async {
    await ApiClient.delete('${ApiEndpoint.users}/$id');
  }
}
