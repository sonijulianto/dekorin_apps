import 'package:dekorin_apps/domain/models/user.dart';

/// Contract for authentication operations.
///
/// Defines the interface that the data layer must implement
/// to provide authentication functionality.
abstract class AuthRepository {
  /// Attempts to log in with the given [email] and [password].
  ///
  /// Returns a [User] on success.
  /// Throws an [Exception] on failure.
  Future<User> login({
    required String email,
    required String password,
  });
}
