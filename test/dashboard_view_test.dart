import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:dekorin_apps/config/theme/app_theme.dart';
import 'package:dekorin_apps/data/repositories/dashboard_repository_impl.dart';
import 'package:dekorin_apps/data/services/expense_service.dart';
import 'package:dekorin_apps/domain/models/agenda.dart';
import 'package:dekorin_apps/domain/models/booking.dart';
import 'package:dekorin_apps/domain/models/dashboard_filter.dart';
import 'package:dekorin_apps/domain/models/dashboard_summary.dart';
import 'package:dekorin_apps/domain/models/expense.dart';
import 'package:dekorin_apps/domain/models/user.dart';
import 'package:dekorin_apps/domain/repositories/dashboard_repository.dart';
import 'package:dekorin_apps/ui/features/dashboard/views/dashboard_view.dart';
import 'package:dekorin_apps/ui/features/login/view_models/global_auth_provider.dart';

class _FakeDashboardRepository implements DashboardRepository {
  @override
  Future<DashboardSummary> getSummary([DashboardFilter? filter]) async {
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
  Future<DashboardSummary> getSummary([DashboardFilter? filter]) async => summary;

  @override
  Future<List<Booking>> getThisWeekBookings() async => [];
}

class _FilterableFakeDashboardRepository implements DashboardRepository {
  _FilterableFakeDashboardRepository({required this.onGetSummary});

  final DashboardSummary Function(DashboardFilter? filter) onGetSummary;

  @override
  Future<DashboardSummary> getSummary([DashboardFilter? filter]) async => onGetSummary(filter);

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

  testWidgets('Tapping an expense item displays ExpenseDetailBottomSheet with neat details', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final summary = DashboardSummary(
      upcomingBookingsCount: 1,
      totalRevenue: 5000000,
      totalExpense: 200000,
      totalProfit: 4800000,
      upcomingAgendas: [],
      recentExpenses: [
        ExpenseItem(
          id: 'exp_bensin_1',
          title: 'Beli bensin',
          amount: 200000,
          category: 'Transport',
          date: DateTime(2026, 10, 26, 14, 30),
          notes: 'Bensin pickup untuk drop alat dekor Graha Saba',
        ),
      ],
    );

    final fakeRepo = _MutableFakeDashboardRepository(summary: summary);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardRepositoryProvider.overrideWithValue(fakeRepo),
          globalAuthProvider.overrideWith(() => _FakeAuthNotifier()),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const DashboardView(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify item is on dashboard
    expect(find.text('Beli bensin'), findsOneWidget);

    // Tap on the card "Beli bensin"
    await tester.tap(find.text('Beli bensin'));
    await tester.pumpAndSettle();

    // Verify detail bottom sheet is displayed with neat details
    expect(find.text('Detail Pengeluaran'), findsOneWidget);
    expect(find.text('Pengeluaran'), findsWidgets);
    expect(find.text('Informasi Transaksi'), findsOneWidget);
    expect(find.text('Kategori'), findsOneWidget);
    expect(find.text('Transport'), findsWidgets);
    expect(find.text('Tanggal Transaksi'), findsOneWidget);
    expect(find.textContaining('26 Oktober 2026'), findsOneWidget);
    expect(find.text('Waktu / Jam'), findsOneWidget);
    expect(find.text('14:30 WIB'), findsOneWidget);
    expect(find.text('ID Transaksi'), findsOneWidget);
    expect(find.textContaining('exp_bensin_1'), findsOneWidget);
    expect(find.text('Catatan / Keterangan'), findsOneWidget);
    expect(find.text('Bensin pickup untuk drop alat dekor Graha Saba'), findsOneWidget);

    // Tap Tutup to dismiss the bottom sheet
    final tutupButton = find.widgetWithText(ElevatedButton, 'Tutup');
    await tester.ensureVisible(tutupButton);
    await tester.tap(tutupButton);
    await tester.pumpAndSettle();

    expect(find.text('Detail Pengeluaran'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Deleting an expense from inside ExpenseDetailBottomSheet triggers confirmation', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final fakeExpenseService = _FakeExpenseService();
    final summary = DashboardSummary(
      upcomingBookingsCount: 0,
      totalRevenue: 0,
      totalExpense: 200000,
      totalProfit: -200000,
      upcomingAgendas: [],
      recentExpenses: [
        ExpenseItem(
          id: 'exp_del_modal',
          title: 'Beli bensin',
          amount: 200000,
          category: 'Transport',
          date: DateTime(2026, 10, 26),
        ),
      ],
    );

    final fakeRepo = _MutableFakeDashboardRepository(summary: summary);

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

    // Tap card to open modal
    await tester.tap(find.text('Beli bensin'));
    await tester.pumpAndSettle();

    expect(find.text('Detail Pengeluaran'), findsOneWidget);

    // Tap Hapus button inside the modal
    final deleteButtonInModal = find.widgetWithText(OutlinedButton, 'Hapus');
    expect(deleteButtonInModal, findsOneWidget);
    await tester.ensureVisible(deleteButtonInModal);
    await tester.tap(deleteButtonInModal);
    await tester.pumpAndSettle();

    // Confirmation dialog appears
    expect(find.text('Hapus Pengeluaran?'), findsOneWidget);
    expect(find.text('Yakin ingin menghapus catatan "Beli bensin"?'), findsOneWidget);

    // Confirm deletion
    final confirmBtn = find.widgetWithText(ElevatedButton, 'Hapus');
    await tester.tap(confirmBtn);
    await tester.pumpAndSettle();

    expect(fakeExpenseService.deleteCalled, isTrue);
    expect(fakeExpenseService.deletedId, 'exp_del_modal');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Dashboard summary defaults to running month and allows switching to Tahun and Semua', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final now = DateTime.now();
    DashboardFilter? lastFilterRequested;

    final summaryMonth = DashboardSummary(
      upcomingBookingsCount: 2,
      totalRevenue: 2500000,
      totalExpense: 100000,
      totalProfit: 2400000,
      upcomingAgendas: [],
      recentExpenses: [],
    );

    final summaryYear = DashboardSummary(
      upcomingBookingsCount: 15,
      totalRevenue: 50000000,
      totalExpense: 5000000,
      totalProfit: 45000000,
      upcomingAgendas: [],
      recentExpenses: [],
    );

    final summaryAll = DashboardSummary(
      upcomingBookingsCount: 25,
      totalRevenue: 90000000,
      totalExpense: 10000000,
      totalProfit: 80000000,
      upcomingAgendas: [],
      recentExpenses: [],
    );

    final fakeRepo = _FilterableFakeDashboardRepository(
      onGetSummary: (filter) {
        lastFilterRequested = filter;
        if (filter?.type == DashboardPeriodType.year) return summaryYear;
        if (filter?.type == DashboardPeriodType.all) return summaryAll;
        return summaryMonth;
      },
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardRepositoryProvider.overrideWithValue(fakeRepo),
          globalAuthProvider.overrideWith(() => _FakeAuthNotifier()),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const DashboardView(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. By default, the active filter is Month (current running month)
    expect(lastFilterRequested, isNotNull);
    expect(lastFilterRequested!.type, DashboardPeriodType.month);
    expect(lastFilterRequested!.month, now.month);
    expect(lastFilterRequested!.year, now.year);

    // Verify filter tabs exist
    expect(find.text('Bulan'), findsOneWidget);
    expect(find.text('Tahun'), findsOneWidget);
    expect(find.text('Semua'), findsOneWidget);

    // Initial nominal corresponds to monthly summary
    expect(find.text('Rp 2.400.000'), findsOneWidget);

    // 2. Switch to 'Tahun'
    await tester.tap(find.text('Tahun'));
    await tester.pumpAndSettle();

    expect(lastFilterRequested!.type, DashboardPeriodType.year);
    expect(find.text('Tahun ${now.year}'), findsWidgets);
    expect(find.text('Rp 45.000.000'), findsOneWidget);

    // 3. Switch to 'Semua'
    await tester.tap(find.text('Semua'));
    await tester.pumpAndSettle();

    expect(lastFilterRequested!.type, DashboardPeriodType.all);
    expect(find.text('Periode: Semua Waktu (Akumulasi)'), findsOneWidget);
    expect(find.text('Rp 80.000.000'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });

  testWidgets('Tapping period label opens MonthYearPickerSheet and selects another month', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    DashboardFilter? lastFilter;
    final fakeRepo = _FilterableFakeDashboardRepository(
      onGetSummary: (filter) {
        lastFilter = filter;
        return DashboardSummary(
          upcomingBookingsCount: 1,
          totalRevenue: 1000000,
          totalExpense: 100000,
          totalProfit: 900000,
          upcomingAgendas: [],
          recentExpenses: [],
        );
      },
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dashboardRepositoryProvider.overrideWithValue(fakeRepo),
          globalAuthProvider.overrideWith(() => _FakeAuthNotifier()),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const DashboardView(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap on the period text to open MonthYearPickerSheet
    final periodFinder = find.text(lastFilter!.displayPeriod);
    expect(periodFinder, findsOneWidget);
    await tester.tap(periodFinder);
    await tester.pumpAndSettle();

    // Verify modal is open
    expect(find.text('Pilih Bulan & Tahun'), findsOneWidget);

    // Tap 'Okt' (Oktober) in the 12-month grid
    await tester.tap(find.text('Okt'));
    await tester.pumpAndSettle();

    // Modal is dismissed and filter updated to month 10
    expect(find.text('Pilih Bulan & Tahun'), findsNothing);
    expect(lastFilter!.month, 10);
    expect(find.textContaining('Oktober'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
