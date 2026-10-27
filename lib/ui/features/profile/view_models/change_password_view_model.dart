import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dekorin_apps/data/datasources/remote/api_client.dart';
import 'package:dekorin_apps/data/repositories/auth_repository_impl.dart';
import 'package:dekorin_apps/domain/repositories/auth_repository.dart';

class ChangePasswordState {
  const ChangePasswordState({
    this.isLoading = false,
    this.isSuccess = false,
    this.errorMessage,
    this.isCurrentPasswordVisible = false,
    this.isNewPasswordVisible = false,
    this.isConfirmPasswordVisible = false,
  });

  final bool isLoading;
  final bool isSuccess;
  final String? errorMessage;
  final bool isCurrentPasswordVisible;
  final bool isNewPasswordVisible;
  final bool isConfirmPasswordVisible;

  ChangePasswordState copyWith({
    bool? isLoading,
    bool? isSuccess,
    String? errorMessage,
    bool clearError = false,
    bool? isCurrentPasswordVisible,
    bool? isNewPasswordVisible,
    bool? isConfirmPasswordVisible,
  }) {
    return ChangePasswordState(
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isCurrentPasswordVisible:
          isCurrentPasswordVisible ?? this.isCurrentPasswordVisible,
      isNewPasswordVisible: isNewPasswordVisible ?? this.isNewPasswordVisible,
      isConfirmPasswordVisible:
          isConfirmPasswordVisible ?? this.isConfirmPasswordVisible,
    );
  }
}

final changePasswordViewModelProvider =
    NotifierProvider.autoDispose<ChangePasswordViewModel, ChangePasswordState>(() {
  return ChangePasswordViewModel();
});

class ChangePasswordViewModel extends AutoDisposeNotifier<ChangePasswordState> {
  late final AuthRepository _authRepository;

  @override
  ChangePasswordState build() {
    _authRepository = ref.watch(authRepositoryProvider);
    return const ChangePasswordState();
  }

  void toggleCurrentPasswordVisibility() {
    state = state.copyWith(
      isCurrentPasswordVisible: !state.isCurrentPasswordVisible,
    );
  }

  void toggleNewPasswordVisibility() {
    state = state.copyWith(
      isNewPasswordVisible: !state.isNewPasswordVisible,
    );
  }

  void toggleConfirmPasswordVisibility() {
    state = state.copyWith(
      isConfirmPasswordVisible: !state.isConfirmPasswordVisible,
    );
  }

  void clearError() {
    if (state.errorMessage != null) {
      state = state.copyWith(clearError: true);
    }
  }

  Future<bool> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final curr = currentPassword.trim();
    final next = newPassword.trim();
    final conf = confirmPassword.trim();

    if (curr.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Password saat ini wajib diisi',
        clearError: false,
      );
      return false;
    }

    if (next.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Password baru wajib diisi',
        clearError: false,
      );
      return false;
    }

    if (next.length < 6) {
      state = state.copyWith(
        errorMessage: 'Password baru minimal 6 karakter',
        clearError: false,
      );
      return false;
    }

    if (curr == next) {
      state = state.copyWith(
        errorMessage: 'Password baru tidak boleh sama dengan password saat ini',
        clearError: false,
      );
      return false;
    }

    if (next != conf) {
      state = state.copyWith(
        errorMessage: 'Konfirmasi password baru tidak cocok',
        clearError: false,
      );
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      await _authRepository.changePassword(
        currentPassword: curr,
        newPassword: next,
      );
      state = state.copyWith(isLoading: false, isSuccess: true);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
        clearError: false,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal mengubah password: $e',
        clearError: false,
      );
      return false;
    }
  }
}
