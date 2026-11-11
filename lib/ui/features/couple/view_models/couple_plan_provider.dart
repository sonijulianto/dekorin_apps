import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:dekorin_apps/data/services/couple_service.dart';
import 'package:dekorin_apps/domain/models/invitation.dart';
import 'package:dekorin_apps/domain/models/wedding_plan.dart';

/// Helper terpusat pemformatan Rupiah untuk fitur Calon Pengantin.
String formatCoupleRupiah(double amount) {
  return NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  ).format(amount);
}

class CoupleWorkspaceState {
  const CoupleWorkspaceState({
    this.isLoading = true,
    this.errorMessage,
    this.planDetail,
    this.vendors = const [],
    this.tasks = const [],
    this.invitations = const [],
  });

  final bool isLoading;
  final String? errorMessage;
  final WeddingPlanDetail? planDetail;
  final List<WeddingPlanVendorItem> vendors;
  final List<WeddingTaskItem> tasks;
  final List<InvitationItem> invitations;

  CoupleWorkspaceState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    WeddingPlanDetail? planDetail,
    List<WeddingPlanVendorItem>? vendors,
    List<WeddingTaskItem>? tasks,
    List<InvitationItem>? invitations,
  }) {
    return CoupleWorkspaceState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      planDetail: planDetail ?? this.planDetail,
      vendors: vendors ?? this.vendors,
      tasks: tasks ?? this.tasks,
      invitations: invitations ?? this.invitations,
    );
  }
}

class CoupleWorkspaceNotifier extends Notifier<CoupleWorkspaceState> {
  @override
  CoupleWorkspaceState build() {
    Future.microtask(refreshAll);
    return const CoupleWorkspaceState(isLoading: true);
  }

  Future<void> refreshAll({bool silent = false}) async {
    if (!silent) {
      state = state.copyWith(isLoading: true, clearError: true);
    }
    try {
      final service = ref.read(coupleServiceProvider);
      final results = await Future.wait([
        service.getMyPlan(),
        service.getVendors(),
        service.getTasks(),
        service.getClaimedInvitations(),
      ]);

      state = CoupleWorkspaceState(
        isLoading: false,
        planDetail: results[0] as WeddingPlanDetail,
        vendors: results[1] as List<WeddingPlanVendorItem>,
        tasks: results[2] as List<WeddingTaskItem>,
        invitations: results[3] as List<InvitationItem>,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> toggleTask(String taskId) async {
    final previousTasks = state.tasks;
    state = state.copyWith(
      tasks: [
        for (final t in previousTasks)
          if (t.id == taskId) t.copyWith(isCompleted: !t.isCompleted) else t,
      ],
    );
    try {
      await ref.read(coupleServiceProvider).toggleTask(taskId);
      await refreshAll(silent: true);
    } catch (e) {
      state = state.copyWith(tasks: previousTasks, errorMessage: e.toString());
      rethrow;
    }
  }

  Future<void> addTask({
    required String title,
    required String category,
    required String phase,
    String dueDate = '',
    String notes = '',
  }) async {
    await ref.read(coupleServiceProvider).createTask(
          title: title,
          category: category,
          phase: phase,
          dueDate: dueDate,
          notes: notes,
        );
    await refreshAll(silent: true);
  }

  Future<void> deleteTask(String taskId) async {
    await ref.read(coupleServiceProvider).deleteTask(taskId);
    await refreshAll(silent: true);
  }
}

final coupleWorkspaceProvider =
    NotifierProvider<CoupleWorkspaceNotifier, CoupleWorkspaceState>(() {
  return CoupleWorkspaceNotifier();
});
