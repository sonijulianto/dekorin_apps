import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dekorin_apps/data/datasources/local/data_preferences.dart';
import 'package:dekorin_apps/data/models/user_model.dart';
import 'package:dekorin_apps/data/services/auth_service.dart';
import 'package:dekorin_apps/domain/models/user.dart';

/// Global provider for Authentication State
final globalAuthProvider = AsyncNotifierProvider<AuthNotifier, User?>(() {
  return AuthNotifier();
});

class AuthNotifier extends AsyncNotifier<User?> {
  @override
  Future<User?> build() async {
    // Pada saat inisialisasi aplikasi, cek apakah ada user tersimpan di HP
    final authService = ref.watch(authServiceProvider);
    final userModel = await authService.getSavedUser();
    return userModel?.toDomain();
  }

  /// Dipanggil dari LoginViewModel setelah login sukses untuk menyimpan state secara global
  void setUser(User user) {
    state = AsyncData(user);
  }

  /// Memperbarui informasi profil usaha / company pada session pengguna aktif
  Future<void> updateCompanyData({
    required String name,
    required String address,
    required String phone,
    String? logoUrl,
    String? email,
    String? description,
    String? instagram,
    String? bankInfo,
  }) async {
    final currentUser = state.value;
    if (currentUser == null) return;

    final updatedUser = currentUser.copyWith(
      companyName: name,
      companyAddress: address,
      companyPhone: phone,
      companyLogo: logoUrl ?? currentUser.companyLogo,
      companyEmail: email ?? currentUser.companyEmail,
      companyDescription: description ?? currentUser.companyDescription,
      companyInstagram: instagram ?? currentUser.companyInstagram,
      companyBankInfo: bankInfo ?? currentUser.companyBankInfo,
    );

    state = AsyncData(updatedUser);

    // Update penyimpanan lokal SharedPreferences agar persisten saat aplikasi dibuka ulang
    final userModel = UserModel(
      id: updatedUser.id,
      fullName: updatedUser.name,
      phone: updatedUser.phone,
      email: updatedUser.email,
      role: updatedUser.role,
      companyId: updatedUser.companyId,
      companyName: updatedUser.companyName,
      companyAddress: updatedUser.companyAddress,
      companyPhone: updatedUser.companyPhone,
      companyLogo: updatedUser.companyLogo,
      companyEmail: updatedUser.companyEmail,
      companyDescription: updatedUser.companyDescription,
      companyInstagram: updatedUser.companyInstagram,
      companyBankInfo: updatedUser.companyBankInfo,
    );
    await DataPreferences.setUser(jsonEncode(userModel.toJson()));
  }

  /// Fungsi untuk Logout
  Future<void> logout() async {
    state = const AsyncLoading(); // Tampilkan state loading jika perlu
    try {
      final authService = ref.watch(authServiceProvider);
      await authService.logout();
      state = const AsyncData(null); // Set user jadi null agar otomatis ke LoginView
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Dipanggil saat sesi expired (HTTP 401) untuk mereset state tanpa async exception
  void forceLogout() {
    state = const AsyncData(null);
  }
}
