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
    this.companyLogo = '',
    this.companyEmail = '',
    this.companyDescription = '',
    this.companyInstagram = '',
    this.companyBankInfo = '',
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
  final String companyLogo;
  final String companyEmail;
  final String companyDescription;
  final String companyInstagram;
  final String companyBankInfo;

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

  /// Owner and Admin can manage company profile & settings
  bool get canManageCompany => isOwner || isAdmin;

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

  User copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? role,
    String? companyId,
    String? companyName,
    String? companyAddress,
    String? companyPhone,
    String? companyLogo,
    String? companyEmail,
    String? companyDescription,
    String? companyInstagram,
    String? companyBankInfo,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      role: role ?? this.role,
      companyId: companyId ?? this.companyId,
      companyName: companyName ?? this.companyName,
      companyAddress: companyAddress ?? this.companyAddress,
      companyPhone: companyPhone ?? this.companyPhone,
      companyLogo: companyLogo ?? this.companyLogo,
      companyEmail: companyEmail ?? this.companyEmail,
      companyDescription: companyDescription ?? this.companyDescription,
      companyInstagram: companyInstagram ?? this.companyInstagram,
      companyBankInfo: companyBankInfo ?? this.companyBankInfo,
    );
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
          companyId == other.companyId &&
          companyLogo == other.companyLogo;

  @override
  int get hashCode => Object.hash(id, name, phone, email, role, companyId, companyLogo);

  @override
  String toString() =>
      'User(id: $id, name: $name, phone: $phone, role: $role, company: $companyName)';
}
