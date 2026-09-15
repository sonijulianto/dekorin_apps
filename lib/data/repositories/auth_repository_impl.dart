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
///
/// Uses [AuthService] to fetch data and transforms it into domain models.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({required AuthService authService})
      : _authService = authService;

  final AuthService _authService;

  @override
  Future<User> login({
    required String email,
    required String password,
  }) async {
    final userModel = await _authService.login(
      email: email,
      password: password,
    );
    return userModel.toDomain();
  }
}
