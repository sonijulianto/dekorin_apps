import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dekorin_apps/data/datasources/remote/api_client.dart';
import 'package:dekorin_apps/data/datasources/remote/api_endpoint.dart';
import 'package:dekorin_apps/domain/models/form_config.dart';

final formConfigServiceProvider = Provider<FormConfigService>((ref) {
  return FormConfigService();
});

class FormConfigService {
  Future<CompanyFormConfig> getFormConfig({String brandId = ''}) async {
    final query = brandId.isNotEmpty ? '?brand_id=${Uri.encodeComponent(brandId)}' : '';
    final response = await ApiClient.get('${ApiEndpoint.formConfig}$query');
    final data = response['data'] as Map<String, dynamic>? ?? {};
    final isInherited = response['is_inherited'] as bool? ?? false;
    return CompanyFormConfig.fromJson(data, isInherited: isInherited);
  }

  Future<CompanyFormConfig> updateFormConfig({
    String brandId = '',
    required bool showPrice,
    required List<FormFieldDefinition> fields,
  }) async {
    final response = await ApiClient.put(
      ApiEndpoint.formConfig,
      body: {
        'brand_id': brandId,
        'show_price': showPrice,
        'fields': fields.map((f) => f.toJson()).toList(),
      },
    );
    final data = response['data'] as Map<String, dynamic>? ?? {};
    return CompanyFormConfig.fromJson(data);
  }

  Future<CompanyFormConfig> resetFormConfig({String brandId = ''}) async {
    final query = brandId.isNotEmpty ? '?brand_id=${Uri.encodeComponent(brandId)}' : '';
    final response = await ApiClient.post('${ApiEndpoint.resetFormConfig}$query');
    final data = response['data'] as Map<String, dynamic>? ?? {};
    final isInherited = response['is_inherited'] as bool? ?? false;
    return CompanyFormConfig.fromJson(data, isInherited: isInherited);
  }
}
