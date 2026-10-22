import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dekorin_apps/data/datasources/remote/api_client.dart';
import 'package:dekorin_apps/data/repositories/auth_repository_impl.dart';
import 'package:dekorin_apps/ui/features/login/view_models/global_auth_provider.dart';

/// State class for Login Screen
class LoginState {
  const LoginState({
    this.isLoading = false,
    this.errorMessage,
    this.isPasswordVisible = false,
  });

  final bool isLoading;
  final String? errorMessage;
  final bool isPasswordVisible;

  LoginState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isPasswordVisible,
    bool clearError = false,
  }) {
    return LoginState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isPasswordVisible: isPasswordVisible ?? this.isPasswordVisible,
    );
  }
}

/// ViewModel (Notifier) for the Login screen.
class LoginViewModel extends Notifier<LoginState> {
  @override
  LoginState build() {
    return const LoginState();
  }

  void togglePasswordVisibility() {
    state = state.copyWith(isPasswordVisible: !state.isPasswordVisible);
  }

  void clearError() {
    if (state.errorMessage != null) {
      state = state.copyWith(clearError: true);
    }
  }

  Future<void> login({
    required String phone,
    required String password,
  }) async {
    final cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');

    // Validasi input
    if (phone.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'Nomor Handphone tidak boleh kosong', clearError: false);
      return;
    }
    if (cleanPhone.length < 9) {
      state = state.copyWith(errorMessage: 'Nomor Handphone minimal 9 digit', clearError: false);
      return;
    }
    if (password.isEmpty) {
      state = state.copyWith(errorMessage: 'Password tidak boleh kosong', clearError: false);
      return;
    }
    if (password.length < 6) {
      state = state.copyWith(errorMessage: 'Password minimal 6 karakter', clearError: false);
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final repository = ref.read(authRepositoryProvider);
      final user = await repository.login(
        phone: phone.trim(),
        password: password,
      );

      // Update global auth state, ini akan men-trigger app.dart untuk pindah halaman
      ref.read(globalAuthProvider.notifier).setUser(user);

      state = state.copyWith(isLoading: false);
    } on ApiException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
      );
    } on Exception catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }
}

/// Provider for LoginViewModel
final loginViewModelProvider = NotifierProvider<LoginViewModel, LoginState>(() {
  return LoginViewModel();
});
