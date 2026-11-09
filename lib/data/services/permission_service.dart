import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dekorin_apps/data/datasources/remote/api_client.dart';
import 'package:dekorin_apps/data/datasources/remote/api_endpoint.dart';
import 'package:dekorin_apps/data/models/role_permission_model.dart';

final permissionServiceProvider = Provider<PermissionService>((ref) {
  return PermissionService();
});

class PermissionService {
  /// Mengambil definisi hak akses dan matriks izin per role untuk perusahaan aktif
  Future<RolePermissionsMatrix> getRolePermissions() async {
    final response = await ApiClient.get(ApiEndpoint.rolePermissions);
    final data = response['data'] ?? response;
    return RolePermissionsMatrix.fromJson(data as Map<String, dynamic>);
  }

  /// Memperbarui hak akses untuk role tertentu ('admin' atau 'crew')
  Future<void> updateRolePermissions({
    required String role,
    required List<String> permissions,
  }) async {
    await ApiClient.put(
      ApiEndpoint.rolePermissions,
      body: {
        'role': role,
        'permissions': permissions,
      },
    );
  }

  /// Mereset hak akses ke setelan bawaan sistem
  Future<void> resetRolePermissions([String? role]) async {
    final query = role != null && role.isNotEmpty ? '?role=$role' : '';
    await ApiClient.post('${ApiEndpoint.resetRolePermissions}$query');
  }
}
