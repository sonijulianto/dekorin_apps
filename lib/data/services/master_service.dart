import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dekorin_apps/data/datasources/remote/api_client.dart';
import 'package:dekorin_apps/data/datasources/remote/api_endpoint.dart';
import 'package:dekorin_apps/domain/models/decoration_addon.dart';
import 'package:dekorin_apps/domain/models/decoration_package.dart';

final masterServiceProvider = Provider<MasterService>((ref) {
  return MasterService();
});

class MasterService {
  // ── PACKAGES ─────────────────────────────────────────────

  Future<List<DecorationPackage>> getPackages() async {
    try {
      final responseData = await ApiClient.get(ApiEndpoint.packages);
      final List<dynamic> data = responseData['data'] as List<dynamic>? ?? [];
      return data.map((item) => DecorationPackage.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<DecorationPackage> createPackage({
    required String name,
    required String description,
    required double basePrice,
    String imageUrl = '',
  }) async {
    final payload = {
      'name': name,
      'description': description,
      'base_price': basePrice,
      'image_url': imageUrl,
    };
    final responseData = await ApiClient.post(ApiEndpoint.packages, body: payload);
    return DecorationPackage.fromJson(responseData['data'] as Map<String, dynamic>);
  }

  Future<DecorationPackage> updatePackage(
    String id, {
    required String name,
    required String description,
    required double basePrice,
    String imageUrl = '',
  }) async {
    final payload = {
      'name': name,
      'description': description,
      'base_price': basePrice,
      'image_url': imageUrl,
    };
    final responseData = await ApiClient.put('${ApiEndpoint.packages}/$id', body: payload);
    return DecorationPackage.fromJson(responseData['data'] as Map<String, dynamic>);
  }

  Future<void> deletePackage(String id) async {
    await ApiClient.delete('${ApiEndpoint.packages}/$id');
  }

  // ── ADDONS ───────────────────────────────────────────────

  Future<List<DecorationAddon>> getAddons() async {
    try {
      final responseData = await ApiClient.get(ApiEndpoint.addons);
      final List<dynamic> data = responseData['data'] as List<dynamic>? ?? [];
      return data.map((item) => DecorationAddon.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
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
}
