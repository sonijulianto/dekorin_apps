import 'package:dekorin_apps/domain/models/user.dart';

/// Data model for user data from API responses.
///
/// Handles serialization/deserialization and mapping to the domain [User].
class UserModel {
  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.role = 'admin',
  });

  final String id;
  final String fullName;
  final String email;
  final String role;

  /// Creates a [UserModel] from a JSON map.
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'admin',
    );
  }

  /// Converts this model to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'role': role,
    };
  }

  /// Maps this data model to the domain [User] model.
  User toDomain() {
    return User(
      id: id,
      name: fullName,
      email: email,
      role: role,
    );
  }
}
