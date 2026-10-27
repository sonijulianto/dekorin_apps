import 'package:flutter_test/flutter_test.dart';
import 'package:dekorin_apps/data/models/user_model.dart';
import 'package:dekorin_apps/domain/models/company_profile.dart';
import 'package:dekorin_apps/domain/models/user.dart';

void main() {
  group('CompanyProfile', () {
    test('fromJson and toJson should work correctly', () {
      final json = {
        'id': 'cmp_123',
        'name': 'Mahakarya Dekorasi',
        'address': 'Jl. Bunga Melati No. 10',
        'phone': '081234567890',
        'email': 'info@mahakarya.id',
        'logo_url': 'https://example.com/logo.png',
        'description': 'Wedding & Luxury Event Decoration',
        'instagram': '@mahakaryadekor',
        'bank_info': 'BCA 123456789 a.n. Mahakarya',
        'updated_by': 'usr_owner_01',
        'updated_by_name': 'Budi Santoso',
        'created_at': '2026-01-01T10:00:00.000Z',
        'updated_at': '2026-02-01T15:30:00.000Z',
      };

      final profile = CompanyProfile.fromJson(json);

      expect(profile.id, 'cmp_123');
      expect(profile.name, 'Mahakarya Dekorasi');
      expect(profile.address, 'Jl. Bunga Melati No. 10');
      expect(profile.phone, '081234567890');
      expect(profile.email, 'info@mahakarya.id');
      expect(profile.logoUrl, 'https://example.com/logo.png');
      expect(profile.description, 'Wedding & Luxury Event Decoration');
      expect(profile.instagram, '@mahakaryadekor');
      expect(profile.bankInfo, 'BCA 123456789 a.n. Mahakarya');
      expect(profile.updatedBy, 'usr_owner_01');
      expect(profile.updatedByName, 'Budi Santoso');
      expect(profile.createdAt, isNotNull);
      expect(profile.updatedAt, isNotNull);

      final output = profile.toJson();
      expect(output['name'], 'Mahakarya Dekorasi');
      expect(output['logo_url'], 'https://example.com/logo.png');
      expect(output['updated_by_name'], 'Budi Santoso');
    });

    test('copyWith should update specified fields', () {
      const profile = CompanyProfile(
        id: 'cmp_1',
        name: 'Dekor A',
        logoUrl: 'https://example.com/a.png',
      );

      final updated = profile.copyWith(
        name: 'Dekor B',
        logoUrl: 'https://example.com/b.png',
        updatedByName: 'Admin Sari',
      );

      expect(updated.id, 'cmp_1');
      expect(updated.name, 'Dekor B');
      expect(updated.logoUrl, 'https://example.com/b.png');
      expect(updated.updatedByName, 'Admin Sari');
    });
  });

  group('User Role & Company Access', () {
    test('canManageCompany is true for Owner and Admin, false for Crew', () {
      const owner = User(id: '1', name: 'Owner', role: 'owner');
      const admin = User(id: '2', name: 'Admin', role: 'admin');
      const crew = User(id: '3', name: 'Crew', role: 'crew');

      expect(owner.canManageCompany, isTrue);
      expect(admin.canManageCompany, isTrue);
      expect(crew.canManageCompany, isFalse);
    });

    test('User copyWith updates company data correctly', () {
      const user = User(
        id: 'usr_1',
        name: 'Owner',
        role: 'owner',
        companyName: 'Lama',
      );

      final updated = user.copyWith(
        companyName: 'Baru',
        companyLogo: 'https://img.com/logo.png',
        companyEmail: 'kontak@baru.com',
        companyBankInfo: 'Bank Mandiri 123',
      );

      expect(updated.companyName, 'Baru');
      expect(updated.companyLogo, 'https://img.com/logo.png');
      expect(updated.companyEmail, 'kontak@baru.com');
      expect(updated.companyBankInfo, 'Bank Mandiri 123');
    });
  });

  group('UserModel', () {
    test('fromJson and toJson include company logo and extra fields', () {
      final json = {
        'id': 'usr_1',
        'full_name': 'Pak Hendra',
        'phone': '0811111111',
        'email': 'hendra@gmail.com',
        'role': 'owner',
        'company_id': 'cmp_1',
        'company_name': 'Hendra Decor',
        'company_address': 'Jakarta',
        'company_phone': '0812345678',
        'company_logo': 'https://domain.com/logo.jpg',
        'company_email': 'decor@hendra.com',
        'company_description': 'Vendor Spesialis Pernikahan',
        'company_instagram': '@hendradecor',
        'company_bank_info': 'BCA 999888',
      };

      final model = UserModel.fromJson(json);
      expect(model.companyLogo, 'https://domain.com/logo.jpg');
      expect(model.companyEmail, 'decor@hendra.com');
      expect(model.companyBankInfo, 'BCA 999888');

      final domain = model.toDomain();
      expect(domain.companyLogo, 'https://domain.com/logo.jpg');
      expect(domain.canManageCompany, isTrue);

      final outputJson = model.toJson();
      expect(outputJson['company_logo'], 'https://domain.com/logo.jpg');
      expect(outputJson['company_bank_info'], 'BCA 999888');
    });
  });
}
