import 'package:dekorin_apps/domain/models/user.dart';

/// Data model for user data from API responses.
class UserModel {
  const UserModel({
    required this.id,
    required this.fullName,
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
  final String fullName;
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

  /// Creates a [UserModel] from a JSON map.
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'crew',
      companyId: json['company_id'] as String? ?? '',
      companyName: json['company_name'] as String? ?? '',
      companyAddress: json['company_address'] as String? ?? '',
      companyPhone: json['company_phone'] as String? ?? '',
      companyLogo: json['company_logo'] as String? ?? '',
      companyEmail: json['company_email'] as String? ?? '',
      companyDescription: json['company_description'] as String? ?? '',
      companyInstagram: json['company_instagram'] as String? ?? '',
      companyBankInfo: json['company_bank_info'] as String? ?? '',
    );
  }

  /// Converts this model to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'phone': phone,
      'email': email,
      'role': role,
      'company_id': companyId,
      'company_name': companyName,
      'company_address': companyAddress,
      'company_phone': companyPhone,
      'company_logo': companyLogo,
      'company_email': companyEmail,
      'company_description': companyDescription,
      'company_instagram': companyInstagram,
      'company_bank_info': companyBankInfo,
    };
  }

  /// Maps this data model to the domain [User] model.
  User toDomain() {
    return User(
      id: id,
      name: fullName,
      phone: phone,
      email: email,
      role: role,
      companyId: companyId,
      companyName: companyName,
      companyAddress: companyAddress,
      companyPhone: companyPhone,
      companyLogo: companyLogo,
      companyEmail: companyEmail,
      companyDescription: companyDescription,
      companyInstagram: companyInstagram,
      companyBankInfo: companyBankInfo,
    );
  }
}
