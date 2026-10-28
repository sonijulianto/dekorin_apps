import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dekorin_apps/data/datasources/remote/api_client.dart';
import 'package:dekorin_apps/data/datasources/remote/api_endpoint.dart';
import 'package:dekorin_apps/domain/models/decoration_addon.dart';
import 'package:dekorin_apps/domain/models/decoration_model.dart';
import 'package:dekorin_apps/domain/models/decoration_package.dart';

final masterServiceProvider = Provider<MasterService>((ref) {
  return MasterService();
});

final packagesProvider = FutureProvider.autoDispose<List<DecorationPackage>>((ref) async {
  final service = ref.watch(masterServiceProvider);
  return service.getPackages();
});

final decorationModelsProvider = FutureProvider.autoDispose<List<DecorationModel>>((ref) async {
  final service = ref.watch(masterServiceProvider);
  return service.getDecorationModels();
});

final addonsProvider = FutureProvider.autoDispose<List<DecorationAddon>>((ref) async {
  final service = ref.watch(masterServiceProvider);
  return service.getAddons();
});

class MasterService {
  // ── PACKAGES ─────────────────────────────────────────────

  Future<List<DecorationPackage>> getPackages() async {
    final responseData = await ApiClient.get(ApiEndpoint.packages);
    final List<dynamic> data = responseData['data'] as List<dynamic>? ?? [];
    return data.map((item) => DecorationPackage.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<DecorationPackage> createPackage({
    String brandId = '',
    required String name,
    required String description,
    required double basePrice,
    String imageUrl = '',
    List<Map<String, dynamic>>? packageModels,
  }) async {
    final payload = <String, dynamic>{
      'brand_id': brandId,
      'name': name,
      'description': description,
      'base_price': basePrice,
      'image_url': imageUrl,
    };
    if (packageModels != null) {
      payload['package_models'] = packageModels;
    }
    final responseData = await ApiClient.post(ApiEndpoint.packages, body: payload);
    return DecorationPackage.fromJson(responseData['data'] as Map<String, dynamic>);
  }

  Future<DecorationPackage> updatePackage(
    String id, {
    String brandId = '',
    required String name,
    required String description,
    required double basePrice,
    String imageUrl = '',
    List<Map<String, dynamic>>? packageModels,
  }) async {
    final payload = <String, dynamic>{
      'brand_id': brandId,
      'name': name,
      'description': description,
      'base_price': basePrice,
      'image_url': imageUrl,
    };
    if (packageModels != null) {
      payload['package_models'] = packageModels;
    }
    final responseData = await ApiClient.put('${ApiEndpoint.packages}/$id', body: payload);
    return DecorationPackage.fromJson(responseData['data'] as Map<String, dynamic>);
  }

  Future<void> deletePackage(String id) async {
    await ApiClient.delete('${ApiEndpoint.packages}/$id');
  }

  Future<void> reorderPackages(List<String> packageIds) async {
    await ApiClient.put(
      ApiEndpoint.reorderPackages,
      body: {'package_ids': packageIds},
    );
  }

  // ── DECORATION MODELS ────────────────────────────────────

  Future<List<DecorationModel>> getDecorationModels() async {
    final responseData = await ApiClient.get(ApiEndpoint.decorationModels);
    final List<dynamic> data = responseData['data'] as List<dynamic>? ?? [];
    return data.map((item) => DecorationModel.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<DecorationModel> createDecorationModel({
    String brandId = '',
    required String name,
    required String width,
    required double price,
    String description = '',
    String imageUrl = '',
    List<Map<String, dynamic>>? modelProperties,
  }) async {
    final payload = <String, dynamic>{
      'brand_id': brandId,
      'name': name,
      'width': width,
      'price': price,
      'description': description,
      'image_url': imageUrl,
    };
    if (modelProperties != null) {
      payload['model_properties'] = modelProperties;
    }
    final responseData = await ApiClient.post(ApiEndpoint.decorationModels, body: payload);
    return DecorationModel.fromJson(responseData['data'] as Map<String, dynamic>);
  }

  Future<DecorationModel> updateDecorationModel(
    String id, {
    String brandId = '',
    required String name,
    required String width,
    required double price,
    String description = '',
    String imageUrl = '',
    List<Map<String, dynamic>>? modelProperties,
  }) async {
    final payload = <String, dynamic>{
      'brand_id': brandId,
      'name': name,
      'width': width,
      'price': price,
      'description': description,
      'image_url': imageUrl,
    };
    if (modelProperties != null) {
      payload['model_properties'] = modelProperties;
    }
    final responseData = await ApiClient.put('${ApiEndpoint.decorationModels}/$id', body: payload);
    return DecorationModel.fromJson(responseData['data'] as Map<String, dynamic>);
  }

  Future<void> deleteDecorationModel(String id) async {
    await ApiClient.delete('${ApiEndpoint.decorationModels}/$id');
  }

  Future<void> reorderDecorationModels(List<String> modelIds) async {
    await ApiClient.put(
      ApiEndpoint.reorderDecorationModels,
      body: {'model_ids': modelIds},
    );
  }

  // ── ADDONS ───────────────────────────────────────────────

  Future<List<DecorationAddon>> getAddons() async {
    final responseData = await ApiClient.get(ApiEndpoint.addons);
    final List<dynamic> data = responseData['data'] as List<dynamic>? ?? [];
    return data.map((item) => DecorationAddon.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<DecorationAddon> createAddon({
    required String name,
    required double price,
    String description = '',
    String imageUrl = '',
  }) async {
    final payload = {
      'name': name,
      'price': price,
      'description': description,
      'image_url': imageUrl,
    };
    final responseData = await ApiClient.post(ApiEndpoint.addons, body: payload);
    return DecorationAddon.fromJson(responseData['data'] as Map<String, dynamic>);
  }

  Future<DecorationAddon> updateAddon(
    String id, {
    required String name,
    required double price,
    String description = '',
    String imageUrl = '',
  }) async {
    final payload = {
      'name': name,
      'price': price,
      'description': description,
      'image_url': imageUrl,
    };
    final responseData = await ApiClient.put('${ApiEndpoint.addons}/$id', body: payload);
    return DecorationAddon.fromJson(responseData['data'] as Map<String, dynamic>);
  }

  Future<void> deleteAddon(String id) async {
    await ApiClient.delete('${ApiEndpoint.addons}/$id');
  }

  Future<void> reorderAddons(List<String> addonIds) async {
    await ApiClient.put(
      ApiEndpoint.reorderAddons,
      body: {'addon_ids': addonIds},
    );
  }
}
