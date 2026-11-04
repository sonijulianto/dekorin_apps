import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:dekorin_apps/config/theme/app_theme.dart';
import 'package:dekorin_apps/data/services/agenda_service.dart';
import 'package:dekorin_apps/domain/models/agenda.dart';
import 'package:dekorin_apps/domain/models/user.dart';
import 'package:dekorin_apps/ui/core/widgets/shimmer_loading.dart';
import 'package:dekorin_apps/ui/features/agenda/views/agenda_view.dart';
import 'package:dekorin_apps/ui/features/login/view_models/global_auth_provider.dart';

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

class _DelayedFakeAgendaService extends AgendaService {
  _DelayedFakeAgendaService({required this.agendasFuture});

  final Future<List<AgendaItem>> agendasFuture;

  @override
  Future<List<AgendaItem>> getAgendas({DateTime? startDate, DateTime? endDate}) {
    return agendasFuture;
  }
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  testWidgets('AgendaView displays AgendaShimmerLoading without full-screen spinner when loading', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final completer = Completer<List<AgendaItem>>();
    final fakeService = _DelayedFakeAgendaService(agendasFuture: completer.future);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          agendaServiceProvider.overrideWithValue(fakeService),
          globalAuthProvider.overrideWith(() => _FakeAuthNotifier()),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const AgendaView(),
        ),
      ),
    );

    // Initial pump while future is still loading
    await tester.pump();

    // Verify filter bar is rendered at the top
    expect(find.text('Agenda Dekorasi'), findsOneWidget);
    expect(find.text('Minggu Ini'), findsOneWidget);

    // Verify shimmer loading skeleton is displayed, and full-screen spinner is NOT displayed
    expect(find.byType(AgendaShimmerLoading), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);

    // Resolve future with agenda items
    completer.complete([
      AgendaItem(
        id: 'agd_1',
        clientName: 'Siti & Budi',
        backdropTitle: 'Wedding of Siti & Budi',
        eventDateTime: DateTime(2026, 11, 15, 10, 0),
        mapsUrl: '',
        packageId: 'pkg_1',
        packageName: 'Paket Elegant Gold',
        packagePrice: 3500000,
        dpAmount: 1000000,
        paymentStatus: 'dp',
        brandName: 'Rustic Luxe',
      ),
    ]);
    await tester.pumpAndSettle();

    // Verify shimmer disappears and real card appears
    expect(find.byType(AgendaShimmerLoading), findsNothing);
    expect(find.text('Siti & Budi'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
