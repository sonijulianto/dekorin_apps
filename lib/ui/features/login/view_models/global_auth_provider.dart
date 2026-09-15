import 'package:flutter_riverpod/flutter_riverpod.dart';

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
}
