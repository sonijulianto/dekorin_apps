import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dekorin_apps/data/models/user_model.dart';
import 'package:dekorin_apps/data/services/auth_service.dart';

/// Provider for managing team members
final teamViewModelProvider =
    AsyncNotifierProvider<TeamViewModel, List<UserModel>>(() {
  return TeamViewModel();
});

class TeamViewModel extends AsyncNotifier<List<UserModel>> {
  @override
  Future<List<UserModel>> build() async {
    return _fetchTeam();
  }

  Future<List<UserModel>> _fetchTeam() async {
    final authService = ref.read(authServiceProvider);
    return await authService.getUsers();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchTeam());
  }

  Future<void> createMember({
    required String fullName,
    required String phone,
    required String password,
    required String role,
    String? email,
  }) async {
    final authService = ref.read(authServiceProvider);
    await authService.createUser(
      fullName: fullName,
      phone: phone,
      password: password,
      role: role,
      email: email,
    );
    await refresh();
  }

  Future<void> updateMember({
    required String id,
    String? fullName,
    String? phone,
    String? email,
    String? password,
    String? role,
  }) async {
    final authService = ref.read(authServiceProvider);
    await authService.updateUser(
      id: id,
      fullName: fullName,
      phone: phone,
      email: email,
      password: password,
      role: role,
    );
    await refresh();
  }

  Future<void> deleteMember(String id) async {
    final authService = ref.read(authServiceProvider);
    await authService.deleteUser(id);
    await refresh();
  }
}
