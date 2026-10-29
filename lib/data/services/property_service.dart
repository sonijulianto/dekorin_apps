import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:dekorin_apps/data/datasources/remote/api_client.dart';
import 'package:dekorin_apps/data/datasources/remote/api_endpoint.dart';
import 'package:dekorin_apps/domain/models/property.dart';

final propertyServiceProvider = Provider<PropertyService>((ref) {
  return PropertyService();
});

final propertiesProvider = FutureProvider.autoDispose<List<Property>>((ref) async {
  final service = ref.watch(propertyServiceProvider);
  return service.getProperties();
});

/// Parameter record untuk availability: (DateTime tanggalAcara, String? excludeAgendaId)
typedef AvailabilityQuery = ({DateTime date, String? excludeAgendaId});

final propertyAvailabilityProvider =
    FutureProvider.autoDispose.family<List<PropertyAvailability>, AvailabilityQuery>((ref, query) async {
  final service = ref.watch(propertyServiceProvider);
  return service.getPropertiesAvailability(query.date, excludeAgendaId: query.excludeAgendaId);
});

final agendaPropertiesProvider =
    FutureProvider.autoDispose.family<List<AgendaProperty>, String>((ref, agendaId) async {
  final service = ref.watch(propertyServiceProvider);
  return service.getAgendaProperties(agendaId);
});

class PropertyService {
  /// Mengambil daftar master properti & alat kerja
  Future<List<Property>> getProperties({String? type, String? category, String? search}) async {
    final queryParams = <String, String>{};
    if (type != null && type.isNotEmpty && type != 'all') {
      queryParams['type'] = type;
    }
    if (category != null && category.isNotEmpty && category != 'all') {
      queryParams['category'] = category;
    }
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }

    String path = ApiEndpoint.properties;
    if (queryParams.isNotEmpty) {
      final queryString = Uri(queryParameters: queryParams).query;
      path = '$path?$queryString';
    }

    final response = await ApiClient.get(path);
    final List<dynamic> data = response['data'] as List<dynamic>? ?? [];
    return data.map((item) => Property.fromJson(item as Map<String, dynamic>)).toList();
  }

  /// Membuat properti / alat baru
  Future<Property> createProperty({
    required String name,
    required String category,
    required String type,
    bool? trackStock,
    required int totalStock,
    String unit = 'pcs',
    String notes = '',
    String imageUrl = '',
  }) async {
    final payload = <String, dynamic>{
      'name': name,
      'category': category,
      'type': type,
      'track_stock': trackStock ?? (type != 'tool'),
      'total_stock': totalStock,
      'unit': unit,
      'notes': notes,
      'image_url': imageUrl,
    };

    final response = await ApiClient.post(ApiEndpoint.properties, body: payload);
    return Property.fromJson(response['data'] as Map<String, dynamic>);
  }

  /// Memperbarui properti / alat
  Future<Property> updateProperty(
    String id, {
    required String name,
    required String category,
    required String type,
    bool? trackStock,
    required int totalStock,
    String unit = 'pcs',
    String notes = '',
    String imageUrl = '',
  }) async {
    final payload = <String, dynamic>{
      'name': name,
      'category': category,
      'type': type,
      'track_stock': trackStock ?? (type != 'tool'),
      'total_stock': totalStock,
      'unit': unit,
      'notes': notes,
      'image_url': imageUrl,
    };

    final response = await ApiClient.put('${ApiEndpoint.properties}/$id', body: payload);
    return Property.fromJson(response['data'] as Map<String, dynamic>);
  }

  /// Menghapus master properti
  Future<void> deleteProperty(String id) async {
    await ApiClient.delete('${ApiEndpoint.properties}/$id');
  }

  /// Cek ketersediaan stok properti di tanggal tertentu
  Future<List<PropertyAvailability>> getPropertiesAvailability(
    DateTime date, {
    String? excludeAgendaId,
  }) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final queryParams = {'date': dateStr};
    if (excludeAgendaId != null && excludeAgendaId.isNotEmpty) {
      queryParams['exclude_agenda_id'] = excludeAgendaId;
    }

    final queryString = Uri(queryParameters: queryParams).query;
    final path = '${ApiEndpoint.propertiesAvailability}?$queryString';

    final response = await ApiClient.get(path);
    final List<dynamic> data = response['data'] as List<dynamic>? ?? [];
    return data.map((item) => PropertyAvailability.fromJson(item as Map<String, dynamic>)).toList();
  }

  /// Mengambil pick list agenda
  Future<List<AgendaProperty>> getAgendaProperties(String agendaId) async {
    final response = await ApiClient.get('${ApiEndpoint.agendas}/$agendaId/properties');
    final List<dynamic> data = response['data'] as List<dynamic>? ?? [];
    return data.map((item) => AgendaProperty.fromJson(item as Map<String, dynamic>)).toList();
  }

  /// Populate pick list dari template model dekorasi
  Future<Map<String, dynamic>> populateAgendaProperties(
    String agendaId, {
    String? modelId,
    String mode = 'replace',
  }) async {
    final payload = <String, dynamic>{
      'mode': mode,
    };
    if (modelId != null && modelId.isNotEmpty) {
      payload['model_id'] = modelId;
    }

    final response = await ApiClient.post('${ApiEndpoint.agendas}/$agendaId/properties/populate', body: payload);
    final List<dynamic> data = response['data'] as List<dynamic>? ?? [];
    final List<dynamic> warnings = response['warnings'] as List<dynamic>? ?? [];

    return {
      'items': data.map((item) => AgendaProperty.fromJson(item as Map<String, dynamic>)).toList(),
      'warnings': warnings.map((w) => w.toString()).toList(),
    };
  }

  /// Tambah item kustom / baru ke pick list agenda
  Future<AgendaProperty> addAgendaProperty(
    String agendaId, {
    required String propertyId,
    String customName = '',
    int qty = 1,
    String notes = '',
  }) async {
    final payload = <String, dynamic>{
      'property_id': propertyId,
      'custom_name': customName,
      'qty': qty,
      'notes': notes,
    };

    final response = await ApiClient.post('${ApiEndpoint.agendas}/$agendaId/properties', body: payload);
    return AgendaProperty.fromJson(response['data'] as Map<String, dynamic>);
  }

  /// Tambah banyak barang sekaligus (Multi-Select) ke pick list agenda
  Future<List<AgendaProperty>> batchAddAgendaProperties(
    String agendaId,
    List<Map<String, dynamic>> items, {
    String mode = 'merge',
  }) async {
    final payload = <String, dynamic>{
      'items': items,
      'mode': mode,
    };

    final response = await ApiClient.post('${ApiEndpoint.agendas}/$agendaId/properties/batch', body: payload);
    final List<dynamic> data = response['data'] as List<dynamic>? ?? [];
    return data.map((item) => AgendaProperty.fromJson(item as Map<String, dynamic>)).toList();
  }

  /// Kosongkan seluruh pick list agenda
  Future<void> clearAgendaProperties(String agendaId) async {
    await ApiClient.delete('${ApiEndpoint.agendas}/$agendaId/properties/clear');
  }

  /// Update item pick list (qty / notes / customName)
  Future<AgendaProperty> updateAgendaProperty(
    String agendaId,
    String itemId, {
    int? qty,
    String? notes,
    String? customName,
    bool? isPacked,
    bool? isReturned,
  }) async {
    final payload = <String, dynamic>{};
    if (qty != null) payload['qty'] = qty;
    if (notes != null) payload['notes'] = notes;
    if (customName != null) payload['custom_name'] = customName;
    if (isPacked != null) payload['is_packed'] = isPacked;
    if (isReturned != null) payload['is_returned'] = isReturned;

    final response = await ApiClient.put('${ApiEndpoint.agendas}/$agendaId/properties/$itemId', body: payload);
    return AgendaProperty.fromJson(response['data'] as Map<String, dynamic>);
  }

  /// Paperless Checklist: Toggle Muat (Berangkat)
  Future<AgendaProperty> togglePacked(String agendaId, String itemId) async {
    final response = await ApiClient.patch('${ApiEndpoint.agendas}/$agendaId/properties/$itemId/pack');
    return AgendaProperty.fromJson(response['data'] as Map<String, dynamic>);
  }

  /// Paperless Checklist: Toggle Bongkar (Pulang)
  Future<AgendaProperty> toggleReturned(String agendaId, String itemId) async {
    final response = await ApiClient.patch('${ApiEndpoint.agendas}/$agendaId/properties/$itemId/return');
    return AgendaProperty.fromJson(response['data'] as Map<String, dynamic>);
  }

  /// Hapus item dari pick list
  Future<void> deleteAgendaProperty(String agendaId, String itemId) async {
    await ApiClient.delete('${ApiEndpoint.agendas}/$agendaId/properties/$itemId');
  }
}
