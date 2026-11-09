import 'package:flutter_test/flutter_test.dart';
import 'package:dekorin_apps/data/models/role_permission_model.dart';
import 'package:dekorin_apps/data/models/user_model.dart';
import 'package:dekorin_apps/domain/models/user.dart';

void main() {
  group('Role Permissions & User Capability Tests', () {
    test('Owner always has all capabilities regardless of permissions list', () {
      const owner = User(
        id: 'usr_owner',
        name: 'Owner Usaha',
        role: 'owner',
        permissions: [], // kosong sekalipun
      );

      expect(owner.isOwner, isTrue);
      expect(owner.can('finance.view_summary'), isTrue);
      expect(owner.can('any.nonexistent.permission'), isTrue);
      expect(owner.canAccessDashboard, isTrue);
      expect(owner.canViewPrice, isTrue);
      expect(owner.canCreateAgenda, isTrue);
      expect(owner.canDeleteAgenda, isTrue);
      expect(owner.canChecklistPicklist, isTrue);
      expect(owner.canManagePicklistItems, isTrue);
      expect(owner.canManageMasterData, isTrue);
      expect(owner.canUseAiStudio, isTrue);
    });

    test('Crew without permissions has restricted access', () {
      const crew = User(
        id: 'usr_crew',
        name: 'Crew Lapangan',
        role: 'crew',
        permissions: ['agenda.view', 'picklist.checklist', 'inventory.view'],
      );

      expect(crew.isOwner, isFalse);
      expect(crew.isCrew, isTrue);
      expect(crew.can('agenda.view'), isTrue);
      expect(crew.can('picklist.checklist'), isTrue);
      expect(crew.can('inventory.view'), isTrue);

      // Keuangan & delete harus false
      expect(crew.can('finance.view_summary'), isFalse);
      expect(crew.canAccessDashboard, isFalse);
      expect(crew.canViewPrice, isFalse);
      expect(crew.canCreateAgenda, isFalse);
      expect(crew.canDeleteAgenda, isFalse);
      expect(crew.canManagePicklistItems, isFalse);
      expect(crew.canManageMasterData, isFalse);
      expect(crew.canUseAiStudio, isFalse);
    });

    test('Admin with dynamic permissions granted can access specified features', () {
      const admin = User(
        id: 'usr_admin',
        name: 'Admin Operasional',
        role: 'admin',
        permissions: [
          'agenda.view',
          'agenda.create',
          'agenda.edit',
          'finance.view_price',
          'picklist.checklist',
          'picklist.manage_items',
          'inventory.view',
          'catalog.manage',
        ],
      );

      expect(admin.isAdmin, isTrue);
      expect(admin.isOwner, isFalse);
      expect(admin.canCreateAgenda, isTrue);
      expect(admin.canEditAgenda, isTrue);
      expect(admin.canViewPrice, isTrue);
      expect(admin.canChecklistPicklist, isTrue);
      expect(admin.canManagePicklistItems, isTrue);
      expect(admin.canManageMasterData, isTrue);

      // delete agenda and finance.view_summary not in permissions
      expect(admin.canDeleteAgenda, isFalse);
      expect(admin.canAccessDashboard, isFalse);
    });

    test('UserModel fromJson and toJson parses permissions array correctly', () {
      final json = {
        'id': 'usr_123',
        'full_name': 'Budi Staff',
        'role': 'crew',
        'permissions': ['agenda.view', 'picklist.checklist'],
      };

      final model = UserModel.fromJson(json);
      expect(model.id, 'usr_123');
      expect(model.fullName, 'Budi Staff');
      expect(model.permissions, ['agenda.view', 'picklist.checklist']);

      final toDomain = model.toDomain();
      expect(toDomain.permissions, ['agenda.view', 'picklist.checklist']);
      expect(toDomain.can('picklist.checklist'), isTrue);
      expect(toDomain.can('agenda.create'), isFalse);

      final exportedJson = model.toJson();
      expect(exportedJson['permissions'], ['agenda.view', 'picklist.checklist']);
    });

    test('RolePermissionsMatrix correctly parses definitions and matrix from JSON', () {
      final json = {
        'definitions': [
          {
            'category': 'Keuangan & Sensitif',
            'permissions': [
              {
                'id': 'finance.view_summary',
                'name': 'Lihat Ringkasan Keuangan',
                'description': 'Melihat omzet di dashboard',
              }
            ]
          }
        ],
        'role_permissions': {
          'admin': ['finance.view_summary', 'agenda.view'],
          'crew': ['agenda.view'],
        }
      };

      final matrix = RolePermissionsMatrix.fromJson(json);
      expect(matrix.definitions.length, 1);
      expect(matrix.definitions.first.category, 'Keuangan & Sensitif');
      expect(matrix.definitions.first.permissions.first.id, 'finance.view_summary');
      expect(matrix.rolePermissions['admin'], contains('finance.view_summary'));
      expect(matrix.rolePermissions['crew'], isNot(contains('finance.view_summary')));
      expect(matrix.rolePermissions['crew'], contains('agenda.view'));
    });
  });
}
