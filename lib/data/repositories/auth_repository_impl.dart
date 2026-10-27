import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dekorin_apps/data/services/auth_service.dart';
import 'package:dekorin_apps/domain/models/user.dart';
import 'package:dekorin_apps/domain/repositories/auth_repository.dart';

/// Provider for AuthRepository
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthRepositoryImpl(authService: authService);
});

/// Concrete implementation of [AuthRepository].
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({required AuthService authService})
      : _authService = authService;

  final AuthService _authService;

  @override
  Future<User> login({
    required String phone,
    required String password,
    String? email,
  }) async {
    final userModel = await _authService.login(
      phone: phone,
      password: password,
      email: email,
    );
    return userModel.toDomain();
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _authService.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
  }
}
