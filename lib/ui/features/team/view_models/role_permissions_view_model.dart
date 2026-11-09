import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dekorin_apps/data/models/role_permission_model.dart';
import 'package:dekorin_apps/data/services/permission_service.dart';
import 'package:dekorin_apps/ui/features/login/view_models/global_auth_provider.dart';

class RolePermissionsState {
  const RolePermissionsState({
    this.isLoading = false,
    this.isSaving = false,
    this.selectedRole = 'admin',
    this.matrix,
    this.rolePermissions = const {},
    this.errorMessage,
    this.successMessage,
  });

  final bool isLoading;
  final bool isSaving;
  final String selectedRole; // 'admin' atau 'crew'
  final RolePermissionsMatrix? matrix;
  final Map<String, Set<String>> rolePermissions;
  final String? errorMessage;
  final String? successMessage;

  RolePermissionsState copyWith({
    bool? isLoading,
    bool? isSaving,
    String? selectedRole,
    RolePermissionsMatrix? matrix,
    Map<String, Set<String>>? rolePermissions,
    String? errorMessage,
    String? successMessage,
  }) {
    return RolePermissionsState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      selectedRole: selectedRole ?? this.selectedRole,
      matrix: matrix ?? this.matrix,
      rolePermissions: rolePermissions ?? this.rolePermissions,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }
}

final rolePermissionsViewModelProvider =
    StateNotifierProvider.autoDispose<RolePermissionsViewModel, RolePermissionsState>(
  (ref) {
    return RolePermissionsViewModel(ref);
  },
);

class RolePermissionsViewModel extends StateNotifier<RolePermissionsState> {
  RolePermissionsViewModel(this._ref) : super(const RolePermissionsState()) {
    loadData();
  }

  final Ref _ref;

  Future<void> loadData() async {
    state = state.copyWith(isLoading: true, errorMessage: null, successMessage: null);
    try {
      final service = _ref.read(permissionServiceProvider);
      final matrix = await service.getRolePermissions();

      final workingMap = <String, Set<String>>{};
      matrix.rolePermissions.forEach((role, perms) {
        workingMap[role] = perms.toSet();
      });

      // Pastikan role 'admin' dan 'crew' selalu ada
      workingMap.putIfAbsent('admin', () => <String>{});
      workingMap.putIfAbsent('crew', () => <String>{});

      state = state.copyWith(
        isLoading: false,
        matrix: matrix,
        rolePermissions: workingMap,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Gagal memuat hak akses: ${e.toString().replaceAll("Exception: ", "")}',
      );
    }
  }

  void selectRole(String role) {
    state = state.copyWith(selectedRole: role, errorMessage: null, successMessage: null);
  }

  void togglePermission(String role, String permKey, bool isEnabled) {
    final currentMap = Map<String, Set<String>>.from(state.rolePermissions);
    final set = Set<String>.from(currentMap[role] ?? <String>{});

    if (isEnabled) {
      set.add(permKey);
    } else {
      set.remove(permKey);
    }

    currentMap[role] = set;
    state = state.copyWith(rolePermissions: currentMap);
  }

  void toggleCategory(String role, List<String> permKeys, bool isEnabled) {
    final currentMap = Map<String, Set<String>>.from(state.rolePermissions);
    final set = Set<String>.from(currentMap[role] ?? <String>{});

    for (final k in permKeys) {
      if (isEnabled) {
        set.add(k);
      } else {
        set.remove(k);
      }
    }

    currentMap[role] = set;
    state = state.copyWith(rolePermissions: currentMap);
  }

  Future<bool> savePermissions() async {
    final role = state.selectedRole;
    final permsToSave = (state.rolePermissions[role] ?? <String>{}).toList();

    state = state.copyWith(isSaving: true, errorMessage: null, successMessage: null);
    try {
      final service = _ref.read(permissionServiceProvider);
      await service.updateRolePermissions(
        role: role,
        permissions: permsToSave,
      );

      // Refresh data profil user aktif (siapa tahu user aktif terdampak)
      _ref.read(globalAuthProvider.notifier).refreshProfile();

      state = state.copyWith(
        isSaving: false,
        successMessage: 'Hak akses untuk ${role == 'admin' ? 'Administrator' : 'Crew Lapangan'} berhasil disimpan!',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Gagal menyimpan hak akses: ${e.toString().replaceAll("Exception: ", "")}',
      );
      return false;
    }
  }

  Future<bool> resetToDefault() async {
    final role = state.selectedRole;
    state = state.copyWith(isSaving: true, errorMessage: null, successMessage: null);
    try {
      final service = _ref.read(permissionServiceProvider);
      await service.resetRolePermissions(role);
      await loadData();

      // Refresh data profil user aktif
      _ref.read(globalAuthProvider.notifier).refreshProfile();

      state = state.copyWith(
        isSaving: false,
        successMessage: 'Hak akses ${role == 'admin' ? 'Administrator' : 'Crew Lapangan'} dikembalikan ke setelan default sistem.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Gagal mereset: ${e.toString().replaceAll("Exception: ", "")}',
      );
      return false;
    }
  }
}
