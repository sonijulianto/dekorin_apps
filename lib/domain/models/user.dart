/// Domain model representing an authenticated user.
class User {
  const User({
    required this.id,
    required this.name,
    this.phone = '',
    this.email = '',
    this.role = 'crew',
    this.companyId = '',
    this.companyName = '',
    this.companyAddress = '',
    this.companyPhone = '',
  });

  final String id;
  final String name;
  final String phone;
  final String email;
  final String role;
  final String companyId;
  final String companyName;
  final String companyAddress;
  final String companyPhone;

  /// Helper getters for Role-Based Access Control
  bool get isOwner => role.toLowerCase() == 'owner';
  bool get isAdmin => role.toLowerCase() == 'admin';
  bool get isCrew => role.toLowerCase() == 'crew';

  /// Owner has access to financial dashboard
  bool get canAccessDashboard => isOwner;

  /// Owner and Admin can create agendas
  bool get canCreateAgenda => isOwner || isAdmin;

  /// Owner and Admin can manage decoration master data
  bool get canManageMasterData => isOwner || isAdmin;

  /// Owner and Admin can manage team members
  bool get canManageTeam => isOwner || isAdmin;

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
          phone == other.phone &&
          email == other.email &&
          role == other.role &&
          companyId == other.companyId;

  @override
  int get hashCode => Object.hash(id, name, phone, email, role, companyId);

  @override
  String toString() =>
      'User(id: $id, name: $name, phone: $phone, role: $role, company: $companyName)';
}
