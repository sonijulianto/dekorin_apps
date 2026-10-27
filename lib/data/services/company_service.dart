import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dekorin_apps/data/datasources/remote/api_client.dart';
import 'package:dekorin_apps/data/datasources/remote/api_endpoint.dart';
import 'package:dekorin_apps/domain/models/company_profile.dart';

final companyServiceProvider = Provider<CompanyService>((ref) {
  return CompanyService();
});

class CompanyService {
  /// Mengambil data profil badan usaha yang sedang aktif
  Future<CompanyProfile> getCompanyProfile() async {
    final response = await ApiClient.get(ApiEndpoint.companyProfile);
    final data = response['data'] ?? response;
    return CompanyProfile.fromJson(data as Map<String, dynamic>);
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
