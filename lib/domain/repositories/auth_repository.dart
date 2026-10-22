import 'package:dekorin_apps/domain/models/user.dart';

/// Contract for authentication operations.
abstract class AuthRepository {
  /// Attempts to log in with the given [phone] and [password].
  Future<User> login({
    required String phone,
    required String password,
    String? email,
  });
}
