import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dekorin_apps/data/datasources/remote/api_client.dart';
import 'package:dekorin_apps/data/datasources/remote/api_endpoint.dart';
import 'package:dekorin_apps/domain/models/company_profile.dart';

final companyServiceProvider = Provider<CompanyService>((ref) {
  return CompanyService();
});

final companyBrandsProvider = FutureProvider.autoDispose<List<CompanyBrand>>((ref) async {
  final service = ref.watch(companyServiceProvider);
  return service.getCompanyBrands();
});

class CompanyService {
  /// Mengambil data profil badan usaha yang sedang aktif
  Future<CompanyProfile> getCompanyProfile() async {
    final response = await ApiClient.get(ApiEndpoint.companyProfile);
    final data = response['data'] ?? response;
    return CompanyProfile.fromJson(data as Map<String, dynamic>);
  }

  /// Mengambil daftar Sub-Brand / Multi-Brand milik perusahaan
  Future<List<CompanyBrand>> getCompanyBrands() async {
    try {
      final response = await ApiClient.get(ApiEndpoint.companyBrands);
      final List<dynamic> data = response['data'] as List<dynamic>? ?? [];
      return data
          .map((item) => CompanyBrand.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Menambahkan Sub-Brand baru
  Future<CompanyBrand> createCompanyBrand({
    required String name,
    String logoUrl = '',
    String description = '',
    String phone = '',
    String instagram = '',
  }) async {
    final response = await ApiClient.post(
      ApiEndpoint.companyBrands,
      body: {
        'name': name,
        'logo_url': logoUrl,
        'description': description,
        'phone': phone,
        'instagram': instagram,
      },
    );
    final data = response['data'] ?? response;
    return CompanyBrand.fromJson(data as Map<String, dynamic>);
  }

  /// Memperbarui data Sub-Brand
  Future<CompanyBrand> updateCompanyBrand(
    String id, {
    required String name,
    String logoUrl = '',
    String description = '',
    String phone = '',
    String instagram = '',
  }) async {
    final response = await ApiClient.put(
      '${ApiEndpoint.companyBrands}/$id',
      body: {
        'name': name,
        'logo_url': logoUrl,
        'description': description,
        'phone': phone,
        'instagram': instagram,
      },
    );
    final data = response['data'] ?? response;
    return CompanyBrand.fromJson(data as Map<String, dynamic>);
  }

  /// Menghapus Sub-Brand
  Future<void> deleteCompanyBrand(String id) async {
    await ApiClient.delete('${ApiEndpoint.companyBrands}/$id');
  }

  /// Memperbarui data profil badan usaha (Hanya Owner & Admin)
  Future<CompanyProfile> updateCompanyProfile({
    required String name,
    required String address,
    required String phone,
    String? email,
    String? logoUrl,
    String? description,
    String? instagram,
    String? bankInfo,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'address': address,
      'phone': phone,
    };
    if (email != null) body['email'] = email;
    if (logoUrl != null) body['logo_url'] = logoUrl;
    if (description != null) body['description'] = description;
    if (instagram != null) body['instagram'] = instagram;
    if (bankInfo != null) body['bank_info'] = bankInfo;

    final response = await ApiClient.put(
      ApiEndpoint.companyProfile,
      body: body,
    );
    final data = response['data'] ?? response;
    return CompanyProfile.fromJson(data as Map<String, dynamic>);
  }
}
