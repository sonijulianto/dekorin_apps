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
    this.companyInvoiceTemplate = 'template_modern_navy',
    this.permissions = const [],
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
  final String companyInvoiceTemplate;
  final List<String> permissions;

  /// Helper getters for Role-Based Access Control
  bool get isSuperAdmin => role.toLowerCase() == 'superadmin';
  bool get isCouple => role.toLowerCase() == 'couple';
  bool get isVendor => !isCouple;
  bool get isOwner => role.toLowerCase() == 'owner' || isSuperAdmin;
  bool get isAdmin => role.toLowerCase() == 'admin' || isSuperAdmin;
  bool get isCrew => role.toLowerCase() == 'crew';

  /// Memeriksa apakah user memiliki izin terhadap fitur tertentu.
  /// Catatan: Superadmin & Owner selalu memiliki izin penuh ke seluruh fitur.
  /// Akun Calon Pengantin ('couple') tidak pernah memiliki izin internal vendor.
  bool can(String permissionKey) {
    if (isCouple) return false;
    if (isOwner) return true;
    return permissions.contains(permissionKey);
  }

  /// Akses ke ringkasan keuangan di Dashboard
  bool get canAccessDashboard => isOwner || can('finance.view_summary');

  /// Akses melihat nominal harga, DP, dan sisa tagihan pada agenda/invoice
  bool get canViewPrice => isOwner || can('finance.view_price');

  /// Akses melihat riwayat biaya operasional dan pengeluaran
  bool get canViewExpenses => isOwner || can('expenses.view');

  /// Akses menambah, mengedit, atau menghapus pengeluaran
  bool get canManageExpenses => isOwner || can('expenses.manage');

  /// Akses membuat agenda acara baru
  bool get canCreateAgenda => isOwner || can('agenda.create');

  /// Akses mengubah rincian agenda acara
  bool get canEditAgenda => isOwner || can('agenda.edit');

  /// Akses menghapus agenda acara
  bool get canDeleteAgenda => isOwner || can('agenda.delete');

  /// Akses mengunduh/mencetak dokumen invoice dan surat jalan
  bool get canDownloadInvoice => isOwner || can('agenda.download_invoice');

  /// Akses mencentang muat (pack) dan kembali (return) pada pick list acara
  bool get canChecklistPicklist => isOwner || can('picklist.checklist');

  /// Akses menambah atau mengurangi barang bawaan pick list acara
  bool get canManagePicklistItems => isOwner || can('picklist.manage_items');

  /// Akses melihat katalog properti & ketersediaan alat dekorasi
  bool get canViewInventory => isOwner || can('inventory.view');

  /// Akses menambah/mengedit/menghapus inventaris properti dan alat
  bool get canManageInventory => isOwner || can('inventory.manage');

  /// Akses mengelola master data katalog paket, addon, dan model dekorasi
  bool get canManageMasterData => isOwner || can('catalog.manage');

  /// Akses mengelola sub-brand perusahaan
  bool get canManageBrand => isOwner || can('brand.manage');

  /// Akses mengelola website undangan digital pengantin
  bool get canManageInvitations => isOwner || can('invitation.manage');

  /// Akses mengelola akun Crew/Staf lapangan
  bool get canManageTeam => isOwner || can('team.manage_crew');

  /// Akses mengelola profil usaha dekorasi & data perusahaan
  bool get canManageCompany => !isCouple && (isOwner || isAdmin);

  /// Akses ke AI Decor Studio & AI Assistant
  bool get canUseAiStudio => isOwner || can('ai.use_studio');

  String get roleDisplayName {
    switch (role.toLowerCase()) {
      case 'superadmin':
        return 'Superadmin';
      case 'owner':
        return 'Owner';
      case 'admin':
        return 'Administrator';
      case 'crew':
        return 'Crew Lapangan';
      case 'couple':
        return 'Calon Pengantin';
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
    String? companyInvoiceTemplate,
    List<String>? permissions,
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
      companyInvoiceTemplate: companyInvoiceTemplate ?? this.companyInvoiceTemplate,
      permissions: permissions ?? this.permissions,
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
