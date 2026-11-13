import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dekorin_apps/data/datasources/remote/api_client.dart';
import 'package:dekorin_apps/data/datasources/remote/api_endpoint.dart';
import 'package:dekorin_apps/domain/models/form_config.dart';

final formConfigServiceProvider = Provider<FormConfigService>((ref) {
  return FormConfigService();
});

class FormConfigService {
  Future<List<FormTemplateSummary>> getFormTemplates({String brandId = ''}) async {
    try {
      final query = brandId.isNotEmpty ? '?brand_id=${Uri.encodeComponent(brandId)}' : '';
      final response = await ApiClient.get('${ApiEndpoint.formConfigTemplates}$query');
      final rawList = response['data'] as List<dynamic>? ?? [];
      if (rawList.isEmpty) return FormTemplateSummary.builtInDefaults;
      return rawList
          .whereType<Map<String, dynamic>>()
          .map(FormTemplateSummary.fromJson)
          .toList();
    } catch (_) {
      return FormTemplateSummary.builtInDefaults;
    }
  }

  String _buildQuery({String brandId = '', String eventType = ''}) {
    final params = <String>[];
    if (brandId.isNotEmpty) {
      params.add('brand_id=${Uri.encodeComponent(brandId)}');
    }
    if (eventType.isNotEmpty) {
      params.add('event_type=${Uri.encodeComponent(eventType)}');
    }
    return params.isEmpty ? '' : '?${params.join('&')}';
  }

  Future<CompanyFormConfig> getFormConfig({
    String brandId = '',
    String eventType = '',
  }) async {
    final query = _buildQuery(brandId: brandId, eventType: eventType);
    final response = await ApiClient.get('${ApiEndpoint.formConfig}$query');
    final data = response['data'] as Map<String, dynamic>? ?? {};
    final isInherited = response['is_inherited'] as bool? ?? false;
    return CompanyFormConfig.fromJson(data, isInherited: isInherited);
  }

  Future<CompanyFormConfig> updateFormConfig({
    String brandId = '',
    String eventType = '',
    String eventLabel = '',
    required bool showPrice,
    required List<FormFieldDefinition> fields,
  }) async {
    final response = await ApiClient.put(
      ApiEndpoint.formConfig,
      body: {
        'brand_id': brandId,
        'event_type': eventType,
        if (eventLabel.trim().isNotEmpty) 'event_label': eventLabel.trim(),
        'show_price': showPrice,
        'fields': fields.map((f) => f.toJson()).toList(),
      },
    );
    final data = response['data'] as Map<String, dynamic>? ?? {};
    return CompanyFormConfig.fromJson(data);
  }

  Future<CompanyFormConfig> resetFormConfig({
    String brandId = '',
    String eventType = '',
  }) async {
    final query = _buildQuery(brandId: brandId, eventType: eventType);
    final response = await ApiClient.post('${ApiEndpoint.resetFormConfig}$query');
    final data = response['data'] as Map<String, dynamic>? ?? {};
    final isInherited = response['is_inherited'] as bool? ?? false;
    return CompanyFormConfig.fromJson(data, isInherited: isInherited);
  }

  Future<void> deleteCustomTemplate({
    String brandId = '',
    required String eventType,
  }) async {
    final query = _buildQuery(brandId: brandId, eventType: eventType);
    await ApiClient.delete('${ApiEndpoint.formConfig}$query');
  }
}
