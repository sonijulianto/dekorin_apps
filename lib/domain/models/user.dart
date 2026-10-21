/// Domain model representing an authenticated user.
class User {
  const User({
    required this.id,
    required this.name,
    required this.email,
    this.role = 'admin',
  });

  final String id;
  final String name;
  final String email;
  final String role;

  /// Helper getters for Role-Based Access Control
  bool get isOwner => role.toLowerCase() == 'owner';
  bool get isAdmin => role.toLowerCase() == 'admin';
  bool get isCrew => role.toLowerCase() == 'crew';

  /// Owner has access to dashboard
  bool get canAccessDashboard => isOwner;

  /// Only Owner and Admin can create agendas
  bool get canCreateAgenda => isOwner || isAdmin;

  /// Only Owner and Admin can manage decoration master data
  bool get canManageMasterData => isOwner || isAdmin;

  String get roleDisplayName {
    switch (role.toLowerCase()) {
      case 'owner':
        return 'Owner';
      case 'admin':
        return 'Administrator';
      case 'crew':
        return 'Crew Lapangan';
      default:
        return role;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          email == other.email &&
          role == other.role;

  @override
  int get hashCode => Object.hash(id, name, email, role);

  @override
  String toString() => 'User(id: $id, name: $name, email: $email, role: $role)';
}
