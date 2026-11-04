import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:dekorin_apps/config/theme/app_theme.dart';
import 'package:dekorin_apps/data/repositories/dashboard_repository_impl.dart';
import 'package:dekorin_apps/data/services/expense_service.dart';
import 'package:dekorin_apps/domain/models/agenda.dart';
import 'package:dekorin_apps/domain/models/booking.dart';
import 'package:dekorin_apps/domain/models/dashboard_summary.dart';
import 'package:dekorin_apps/domain/models/expense.dart';
import 'package:dekorin_apps/domain/models/user.dart';
import 'package:dekorin_apps/domain/repositories/dashboard_repository.dart';
import 'package:dekorin_apps/ui/features/dashboard/views/dashboard_view.dart';
import 'package:dekorin_apps/ui/features/login/view_models/global_auth_provider.dart';

class _FakeDashboardRepository implements DashboardRepository {
  @override
  Future<DashboardSummary> getSummary() async {
    return DashboardSummary(
      upcomingBookingsCount: 3,
      totalRevenue: 5350000,
      totalExpense: 200000,
      totalProfit: 5150000,
      upcomingAgendas: [
        AgendaItem(
          id: '1',
          clientName: 'Dita',
          backdropTitle: 'Dita & Dito',
          eventDateTime: DateTime(2026, 11, 8),
          mapsUrl: '',
          packageId: 'p1',
          packageName: 'Paket Akad',
          packagePrice: 190000,
          dpAmount: 100000,
          paymentStatus: 'dp',
        ),
        AgendaItem(
          id: '2',
          clientName: 'Omah Pengantin',
          backdropTitle: 'Acara Omah Pengantin',
          eventDateTime: DateTime(2026, 12, 12),
          mapsUrl: '',
          packageId: 'p2',
          packageName: 'Paket Resepsi',
          packagePrice: 1400000,
          dpAmount: 500000,
          paymentStatus: 'dp',
        ),
        AgendaItem(
          id: '3',
          clientName: 'Aurellia',
          backdropTitle: 'Lia dan Irdi',
          eventDateTime: DateTime(2027, 3, 27),
          mapsUrl: '',
          packageId: 'p3',
          packageName: 'Paket Luxury',
          packagePrice: 3500000,
          dpAmount: 0,
          paymentStatus: 'paid',
        ),
      ],
      recentExpenses: [
        ExpenseItem(
          id: 'e1',
          title: 'Beli bensin',
          amount: 200000,
          category: 'Transport',
          date: DateTime(2026, 10, 26),
        ),
      ],
    );
  }

  @override
  Future<List<Booking>> getThisWeekBookings() async => [];
}

class _FakeExpenseService extends ExpenseService {
  bool deleteCalled = false;
  String? deletedId;

  @override
  Future<void> deleteExpense(String id) async {
    deleteCalled = true;
    deletedId = id;
  }
}

class _MutableFakeDashboardRepository implements DashboardRepository {
  _MutableFakeDashboardRepository({required this.summary});

  DashboardSummary summary;

  @override
  Future<DashboardSummary> getSummary() async => summary;

  @override
  Future<List<Booking>> getThisWeekBookings() async => [];
}

class _FakeAuthNotifier extends AuthNotifier {
  @override
  Future<User?> build() async {
    return const User(
      id: 'u1',
      name: 'Admin',
      role: 'owner',
    );
  }
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  testWidgets('DashboardView renders redesigned layout without overflow', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardRepositoryProvider.overrideWithValue(_FakeDashboardRepository()),
          globalAuthProvider.overrideWith(() => _FakeAuthNotifier()),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const DashboardView(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.textContaining('Halo, Admin', findRichText: true), findsOneWidget);
    expect(find.text('Keuntungan (Pendapatan - Beban)'), findsOneWidget);
    expect(find.text('Pendapatan'), findsOneWidget);
    expect(find.text('Pengeluaran'), findsOneWidget);
    expect(find.text('Agenda'), findsOneWidget);
    expect(find.text('Booking Mendatang'), findsOneWidget);
    expect(find.text('Dita'), findsOneWidget);
    expect(find.text('Omah Pengantin'), findsOneWidget);
    expect(find.text('Pengeluaran Terkini'), findsOneWidget);
    expect(find.text('Beli bensin'), findsOneWidget);
    expect(find.text('Catat Pengeluaran'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('DashboardView handles narrow 320px screen without overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardRepositoryProvider.overrideWithValue(_FakeDashboardRepository()),
          globalAuthProvider.overrideWith(() => _FakeAuthNotifier()),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const DashboardView(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Deleting an expense updates only pengeluaran and shimmers nominals without full-screen refresh', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final fakeExpenseService = _FakeExpenseService();
    final initialSummary = DashboardSummary(
      upcomingBookingsCount: 1,
      totalRevenue: 5000000,
      totalExpense: 200000,
      totalProfit: 4800000,
      upcomingAgendas: [],
      recentExpenses: [
        ExpenseItem(
          id: 'exp_test_1',
          title: 'Beli bunga mawar',
          amount: 200000,
          category: 'Bunga',
          date: DateTime(2026, 11, 1),
        ),
      ],
    );

    final fakeRepo = _MutableFakeDashboardRepository(summary: initialSummary);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardRepositoryProvider.overrideWithValue(fakeRepo),
          expenseServiceProvider.overrideWithValue(fakeExpenseService),
          globalAuthProvider.overrideWith(() => _FakeAuthNotifier()),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const DashboardView(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify initial item is shown
    expect(find.text('Beli bunga mawar'), findsOneWidget);
    expect(find.text('Hapus'), findsOneWidget);

    // Tap Hapus button to trigger confirmation dialog
    await tester.tap(find.text('Hapus'));
    await tester.pumpAndSettle();

    expect(find.text('Hapus Pengeluaran?'), findsOneWidget);

    // Update fakeRepo summary to reflect deletion after backend call
    fakeRepo.summary = initialSummary.copyWith(
      totalExpense: 0,
      totalProfit: 5000000,
      recentExpenses: [],
    );

    // Tap Hapus in dialog
    final confirmDeleteButton = find.widgetWithText(ElevatedButton, 'Hapus');
    await tester.tap(confirmDeleteButton);

    // Pump dialog dismiss and optimistic update
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // The whole screen should NOT be replaced by a full-screen CircularProgressIndicator
    expect(find.byType(CircularProgressIndicator), findsNothing);

    // Optimistically, the deleted expense is immediately gone from the list
    expect(find.text('Beli bunga mawar'), findsNothing);
    expect(find.text('Belum ada catatan pengeluaran.'), findsOneWidget);

    // Shimmer box for nominals should be active during loading
    expect(find.byKey(const ValueKey('hero_profit_shimmer')), findsOneWidget);

    // Fast-forward animation and wait for deletion, summary refresh, and AnimatedSwitcher transition
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify expense service was invoked with correct id
    expect(fakeExpenseService.deleteCalled, isTrue);
    expect(fakeExpenseService.deletedId, 'exp_test_1');

    // After deletion, shimmer is gone, updated nominals appear and snackbar is visible
    expect(find.byKey(const ValueKey('hero_profit_shimmer')), findsNothing);
    expect(find.text('Pengeluaran berhasil dihapus'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
