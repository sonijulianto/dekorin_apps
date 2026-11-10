import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:dekorin_apps/config/theme/app_theme.dart';
import 'package:dekorin_apps/data/services/agenda_service.dart';
import 'package:dekorin_apps/data/services/company_service.dart';
import 'package:dekorin_apps/data/services/property_service.dart';
import 'package:dekorin_apps/domain/models/agenda.dart';
import 'package:dekorin_apps/domain/models/company_profile.dart';
import 'package:dekorin_apps/domain/models/property.dart';
import 'package:dekorin_apps/domain/models/user.dart';
import 'package:dekorin_apps/ui/features/agenda/views/agenda_detail_view.dart';
import 'package:dekorin_apps/ui/features/agenda/views/create_agenda_sheet.dart';
import 'package:dekorin_apps/ui/features/login/view_models/global_auth_provider.dart';

class _FakeAuthNotifier extends AuthNotifier {
  @override
  Future<User?> build() async {
    return const User(
      id: 'u1',
      name: 'Owner Test',
      role: 'owner',
      companyName: 'Dekorin Studio',
    );
  }
}

class _FakeAgendaService extends AgendaService {
  _FakeAgendaService(this.onUpdatePaymentStatus);

  final Future<AgendaItem> Function(
    String agendaId,
    String paymentStatus,
    DateTime? fallbackEventDateTime,
  ) onUpdatePaymentStatus;

  @override
  Future<AgendaItem> updatePaymentStatus(
    String agendaId,
    String paymentStatus, {
    DateTime? fallbackEventDateTime,
  }) {
    return onUpdatePaymentStatus(agendaId, paymentStatus, fallbackEventDateTime);
  }
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  group('Agenda schedule preservation when marking as paid', () {
    test('AgendaItem.fromJson uses fallbackEventDateTime when event_date_time is missing or zero', () {
      final originalDate = DateTime(2026, 12, 25, 10, 0);

      final fromMissing = AgendaItem.fromJson(
        {
          'id': 'agd_1',
          'client_name': 'Rian & Nisa',
          'payment_status': 'paid',
        },
        fallbackEventDateTime: originalDate,
      );
      expect(fromMissing.eventDateTime, originalDate);

      final fromZeroDate = AgendaItem.fromJson(
        {
          'id': 'agd_1',
          'client_name': 'Rian & Nisa',
          'event_date_time': '0001-01-01T00:00:00Z',
          'payment_status': 'paid',
        },
        fallbackEventDateTime: originalDate,
      );
      expect(fromZeroDate.eventDateTime, originalDate);
    });

    testWidgets('Marking agenda as LUNAS in AgendaDetailView preserves original eventDateTime', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final originalDate = DateTime(2026, 12, 25, 10, 0);
      final initialItem = AgendaItem(
        id: 'agd_preserve_1',
        clientName: 'Siti & Budi',
        backdropTitle: 'Wedding Siti & Budi',
        eventDateTime: originalDate,
        mapsUrl: '',
        packageId: 'pkg_1',
        packageName: 'Paket Gold',
        packagePrice: 5000000,
        dpAmount: 1000000,
        paymentStatus: 'dp',
      );

      final fakeService = _FakeAgendaService((id, status, fallback) async {
        // Simulasikan skenario respons server mengembalikan event_date_time kosong/hilang
        // sehingga parser harus mempertahankan fallback jadwal asli.
        return AgendaItem.fromJson(
          {
            'id': id,
            'client_name': 'Siti & Budi',
            'backdrop_title': 'Wedding Siti & Budi',
            'package_id': 'pkg_1',
            'package_name': 'Paket Gold',
            'package_price': 5000000,
            'dp_amount': 5000000,
            'payment_status': status,
            'status': 'upcoming',
          },
          fallbackEventDateTime: fallback,
        );
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            globalAuthProvider.overrideWith(() => _FakeAuthNotifier()),
            agendaServiceProvider.overrideWithValue(fakeService),
            companyBrandsProvider.overrideWith((ref) async => const <CompanyBrand>[]),
            agendaPropertiesProvider('agd_preserve_1').overrideWith((ref) async => const <AgendaProperty>[]),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: AgendaDetailView(item: initialItem),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Pastikan jadwal awal tampil: Jumat, 25 Desember 2026
      expect(find.text('Jumat, 25 Desember 2026'), findsOneWidget);

      // Scroll ke tombol Tandai Pembayaran Lunas lalu tekan
      final markPaidBtn = find.text('Tandai Pembayaran Lunas');
      await tester.scrollUntilVisible(markPaidBtn, 300, scrollable: find.byType(Scrollable).first);
      await tester.tap(markPaidBtn);
      await tester.pumpAndSettle();

      // Konfirmasi dialog "Ya, Sudah Lunas"
      await tester.tap(find.text('Ya, Sudah Lunas'));
      await tester.pumpAndSettle();

      // Status harus menjadi LUNAS, tetapi jadwal acara harus TETAP 25 Desember 2026!
      expect(find.text('LUNAS'), findsOneWidget);
      expect(find.text('Jumat, 25 Desember 2026'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('CreateAgendaSheet.resolveEventDateTime', () {
    test('defaults time to 10:00 when date is selected without explicit time', () {
      final result = CreateAgendaSheet.resolveEventDateTime(
        DateTime(2026, 11, 8),
        null,
      );

      expect(result, DateTime(2026, 11, 8, 10, 0));
    });

    test('uses both selected date and time when provided', () {
      final result = CreateAgendaSheet.resolveEventDateTime(
        DateTime(2026, 11, 8),
        const TimeOfDay(hour: 14, minute: 30),
      );

      expect(result, DateTime(2026, 11, 8, 14, 30));
    });

    test('returns null when no date is selected', () {
      final result = CreateAgendaSheet.resolveEventDateTime(
        null,
        const TimeOfDay(hour: 10, minute: 0),
      );

      expect(result, isNull);
    });
  });
}
