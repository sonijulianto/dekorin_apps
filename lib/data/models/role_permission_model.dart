class PermissionItemModel {
  const PermissionItemModel({
    required this.id,
    required this.name,
    required this.description,
  });

  final String id;
  final String name;
  final String description;

  factory PermissionItemModel.fromJson(Map<String, dynamic> json) {
    return PermissionItemModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
      };
}

class PermissionCategoryModel {
  const PermissionCategoryModel({
    required this.category,
    required this.permissions,
  });

  final String category;
  final List<PermissionItemModel> permissions;

  factory PermissionCategoryModel.fromJson(Map<String, dynamic> json) {
    final list = (json['permissions'] as List<dynamic>?) ?? [];
    return PermissionCategoryModel(
      category: json['category'] as String? ?? '',
      permissions: list
          .map((e) => PermissionItemModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'category': category,
        'permissions': permissions.map((e) => e.toJson()).toList(),
      };
}

class RolePermissionsMatrix {
  const RolePermissionsMatrix({
    required this.definitions,
    required this.rolePermissions,
  });

  final List<PermissionCategoryModel> definitions;
  final Map<String, List<String>> rolePermissions;

  factory RolePermissionsMatrix.fromJson(Map<String, dynamic> json) {
    final defs = (json['definitions'] as List<dynamic>?) ?? [];
    final rolePermsRaw = (json['role_permissions'] as Map<String, dynamic>?) ?? {};

    final Map<String, List<String>> rolePerms = {};
    rolePermsRaw.forEach((key, val) {
      if (val is List) {
        rolePerms[key] = val.map((e) => e.toString()).toList();
      } else {
        rolePerms[key] = [];
      }
    });

    return RolePermissionsMatrix(
      definitions: defs
          .map((e) => PermissionCategoryModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      rolePermissions: rolePerms,
    );
  }
}
