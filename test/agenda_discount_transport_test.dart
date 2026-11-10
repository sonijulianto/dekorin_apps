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
import 'package:dekorin_apps/domain/models/invoice_template.dart';
import 'package:dekorin_apps/domain/models/property.dart';
import 'package:dekorin_apps/domain/models/user.dart';
import 'package:dekorin_apps/ui/features/agenda/views/agenda_detail_view.dart';
import 'package:dekorin_apps/ui/features/agenda/views/agenda_edit_view.dart';
import 'package:dekorin_apps/ui/features/agenda/views/create_agenda_sheet.dart';
import 'package:dekorin_apps/ui/features/agenda/views/invoice_pdf_helper.dart';
import 'package:dekorin_apps/ui/features/login/view_models/global_auth_provider.dart';

class _StubAuthNotifier extends AuthNotifier {
  @override
  Future<User?> build() async {
    return const User(
      id: 'usr_owner',
      name: 'Owner Test',
      role: 'owner',
      companyName: 'Dekorin Studio',
    );
  }
}

class _CapturingAgendaService extends AgendaService {
  Map<String, dynamic>? lastCreateArgs;
  Map<String, dynamic>? lastUpdateArgs;

  @override
  Future<List<AgendaItem>> getAgendas({DateTime? startDate, DateTime? endDate}) async => [];

  @override
  Future<AgendaItem> updateAgenda(
    String agendaId, {
    String brandId = '',
    required String clientName,
    String clientPhone = '',
    String backdropTitle = '',
    DateTime? eventDateTime,
    String eventAddress = '',
    String mapsUrl = '',
    String packageId = '',
    String packageName = '',
    double packagePrice = 0.0,
    String modelId = '',
    String modelName = '',
    String modelWidth = '',
    String modelImageUrl = '',
    double modelAdditionalPrice = 0.0,
    String discountType = 'amount',
    double discountValue = 0.0,
    double transportFee = 0.0,
    double dpAmount = 0.0,
    String paymentStatus = '',
    String status = '',
    String notes = '',
  }) async {
    lastUpdateArgs = {
      'id': agendaId,
      'discountType': discountType,
      'discountValue': discountValue,
      'transportFee': transportFee,
      'dpAmount': dpAmount,
    };
    return AgendaItem(
      id: agendaId,
      clientName: clientName,
      clientPhone: clientPhone,
      backdropTitle: backdropTitle,
      eventDateTime: eventDateTime ?? DateTime(2026, 12, 20),
      mapsUrl: mapsUrl,
      packageId: packageId,
      packageName: packageName,
      packagePrice: packagePrice,
      modelAdditionalPrice: modelAdditionalPrice,
      discountType: discountType,
      discountValue: discountValue,
      transportFee: transportFee,
      dpAmount: dpAmount,
      paymentStatus: paymentStatus,
      status: status,
      notes: notes,
    );
  }

  @override
  Future<AgendaItem> createAgenda({
    String brandId = '',
    required String clientName,
    String clientPhone = '',
    String backdropTitle = '',
    DateTime? eventDateTime,
    String eventAddress = '',
    String mapsUrl = '',
    String packageId = '',
    double packagePrice = 0.0,
    String modelId = '',
    String modelName = '',
    String modelWidth = '',
    String modelImageUrl = '',
    double modelAdditionalPrice = 0.0,
    String discountType = 'amount',
    double discountValue = 0.0,
    double transportFee = 0.0,
    double dpAmount = 0.0,
    String paymentStatus = '',
    String notes = '',
  }) async {
    lastCreateArgs = {
      'clientName': clientName,
      'clientPhone': clientPhone,
      'discountType': discountType,
      'discountValue': discountValue,
      'transportFee': transportFee,
      'dpAmount': dpAmount,
    };
    return AgendaItem(
      id: 'agd_new',
      clientName: clientName,
      clientPhone: clientPhone,
      backdropTitle: backdropTitle,
      eventDateTime: eventDateTime ?? DateTime(2026, 12, 20),
      mapsUrl: mapsUrl,
      packageId: packageId,
      packageName: '',
      packagePrice: packagePrice,
      discountType: discountType,
      discountValue: discountValue,
      transportFee: transportFee,
      dpAmount: dpAmount,
      notes: notes,
    );
  }
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('id_ID', null);
  });

  group('AgendaItem Discount & Transport Isolation', () {
    test('Percent discount only cuts decor subtotal and excludes transportFee', () {
      final agenda = AgendaItem(
        id: 'agd_pct',
        clientName: 'Rian & Nisa',
        backdropTitle: 'Engagement',
        eventDateTime: DateTime(2026, 11, 20),
        mapsUrl: '',
        packageId: 'pkg_1',
        packageName: 'Paket Silver',
        packagePrice: 4000000,
        modelAdditionalPrice: 200000,
        discountType: 'percent',
        discountValue: 10,
        transportFee: 300000,
        dpAmount: 1000000,
        notes: '[Item Tambahan / Addon]:\n- Lighting (Rp 300.000)',
      );

      // Decor subtotal = 4.000.000 + 200.000 + 300.000 = 4.500.000
      expect(agenda.calculatedDecorSubtotal, 4500000.0);
      // 10% discount = 450.000 (Transport 300.000 is NOT included)
      expect(agenda.calculatedDiscountAmount, 450000.0);
      // Total = (4.500.000 - 450.000) + 300.000 = 4.350.000
      expect(agenda.calculatedTotalPrice, 4350000.0);
      // Remaining = 4.350.000 - 1.000.000 = 3.350.000
      expect(agenda.calculatedRemainingPayment, 3350000.0);
    });

    test('Nominal Rp discount clamps at decor subtotal so transport stays intact', () {
      final agenda = AgendaItem(
        id: 'agd_amt',
        clientName: 'Budi',
        backdropTitle: 'Akad',
        eventDateTime: DateTime(2026, 11, 22),
        mapsUrl: '',
        packageId: 'pkg_1',
        packageName: 'Paket Akad',
        packagePrice: 1000000,
        discountType: 'amount',
        discountValue: 1500000,
        transportFee: 250000,
      );

      expect(agenda.calculatedDecorSubtotal, 1000000.0);
      expect(agenda.calculatedDiscountAmount, 1000000.0);
      expect(agenda.calculatedTotalPrice, 250000.0);
    });

    test('fromJson defaults gracefully when discount fields are missing in legacy payloads', () {
      final legacy = AgendaItem.fromJson({
        'id': 'agd_legacy',
        'client_name': 'Klien Lama',
        'package_price': 2500000,
        'transport_fee': 200000,
      });

      expect(legacy.discountType, 'amount');
      expect(legacy.discountValue, 0.0);
      expect(legacy.calculatedDiscountAmount, 0.0);
      expect(legacy.calculatedTotalPrice, 2700000.0);
    });
  });

  group('InvoicePdfHelper Unified Template 2 Standard', () {
    test('buildAllInvoiceItems excludes TRANSPORT and calculatePricingSummary isolates discount', () async {
      final agenda = AgendaItem(
        id: 'agd_inv_1',
        clientName: 'Juwita',
        backdropTitle: 'Wedding',
        eventDateTime: DateTime(2026, 12, 1),
        mapsUrl: '',
        packageId: 'pkg_1',
        packageName: 'Backdrop Platinum',
        packagePrice: 2000000,
        discountType: 'percent',
        discountValue: 10,
        transportFee: 500000,
        dpAmount: 700000,
        notes: '[Item Tambahan / Addon]:\n- Spotlight (Rp 500.000)',
      );

      final itemsUpper = InvoicePdfHelper.buildAllInvoiceItems(agenda, uppercase: true);
      expect(itemsUpper.any((it) => it.name.contains('TRANSPORT')), isFalse);
      expect(itemsUpper.length, 2);

      final summary = InvoicePdfHelper.calculatePricingSummary(agenda);
      expect(summary.subtotal, 2500000.0);
      expect(summary.discountAmount, 250000.0);
      expect(summary.discountLabel, 'Discount (10%)');
      expect(summary.transportFee, 500000.0);
      expect(summary.totalTagihan, 2750000.0);
      expect(summary.grandTotal, 2050000.0);

      for (final tmpl in InvoiceTemplate.values) {
        final bytes = await InvoicePdfHelper.generateInvoicePdf(agenda, template: tmpl);
        expect(bytes.length, greaterThan(100));
        expect(String.fromCharCodes(bytes.take(4)), '%PDF');
      }
    });
  });

  group('CreateAgendaSheet & AgendaDetailView UI Flows', () {
    testWidgets('CreateAgendaSheet lets user input Discount (Rp/%), Transport, and DP at creation', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final capturingService = _CapturingAgendaService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            globalAuthProvider.overrideWith(() => _StubAuthNotifier()),
            agendaServiceProvider.overrideWithValue(capturingService),
            companyBrandsProvider.overrideWith((ref) async => const <CompanyBrand>[]),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const Scaffold(body: CreateAgendaSheet()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Isi nama & no HP wajib
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Rian & Nisa');
      await tester.enterText(fields.at(1), '081234567890');

      // Scroll ke bagian Diskon, Transport & DP
      final discountHeader = find.text('Diskon, Transport & DP (Opsional)');
      await tester.scrollUntilVisible(discountHeader, 300, scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();

      // Pilih mode diskon '%'
      await tester.tap(find.text('%'));
      await tester.pumpAndSettle();

      // Isi Diskon = 10, Transport = 300000, DP = 1000000
      final discountField = find.widgetWithText(TextFormField, '0 (misal: 10)');
      await tester.enterText(discountField, '10');

      final transportInput = find.ancestor(
        of: find.text('Ongkos Kirim / Uang Transport'),
        matching: find.byType(Column),
      ).first;
      await tester.enterText(find.descendant(of: transportInput, matching: find.byType(TextFormField)), '300000');

      final dpInput = find.ancestor(
        of: find.text('Nominal DP Masuk'),
        matching: find.byType(Column),
      ).first;
      await tester.enterText(find.descendant(of: dpInput, matching: find.byType(TextFormField)), '1000000');
      await tester.pumpAndSettle();

      // Submit agenda
      final saveBtn = find.text('Simpan Agenda');
      await tester.scrollUntilVisible(saveBtn, 300, scrollable: find.byType(Scrollable).first);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      expect(capturingService.lastCreateArgs, isNotNull);
      expect(capturingService.lastCreateArgs!['discountType'], 'percent');
      expect(capturingService.lastCreateArgs!['discountValue'], 10.0);
      expect(capturingService.lastCreateArgs!['transportFee'], 300000.0);
      expect(capturingService.lastCreateArgs!['dpAmount'], 1000000.0);
    });

    testWidgets('AgendaDetailView hides discount when 0', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final noDiscountItem = AgendaItem(
        id: 'agd_nodisc',
        clientName: 'Siti',
        backdropTitle: 'Lamaran',
        eventDateTime: DateTime(2026, 12, 25, 10, 0),
        mapsUrl: '',
        packageId: 'pkg_1',
        packageName: 'Paket Silver',
        packagePrice: 4000000,
        transportFee: 300000,
        dpAmount: 1000000,
        paymentStatus: 'dp',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            globalAuthProvider.overrideWith(() => _StubAuthNotifier()),
            companyBrandsProvider.overrideWith((ref) async => const <CompanyBrand>[]),
            agendaPropertiesProvider('agd_nodisc').overrideWith((ref) async => const <AgendaProperty>[]),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: AgendaDetailView(item: noDiscountItem),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(find.text('Ringkasan Biaya & Pembayaran'), 300, scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();

      expect(find.textContaining('Diskon'), findsNothing);
      expect(find.text('Subtotal Dekorasi'), findsOneWidget);
      expect(find.text('Ongkos Kirim / Transport'), findsOneWidget);
    });

    testWidgets('AgendaDetailView orders Subtotal -> Diskon -> Transport + DP + Sisa without discounting transport', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final withDiscountItem = AgendaItem(
        id: 'agd_withdisc',
        clientName: 'Siti',
        backdropTitle: 'Lamaran',
        eventDateTime: DateTime(2026, 12, 25, 10, 0),
        mapsUrl: '',
        packageId: 'pkg_1',
        packageName: 'Paket Silver',
        packagePrice: 4000000,
        discountType: 'percent',
        discountValue: 10,
        transportFee: 300000,
        dpAmount: 1000000,
        paymentStatus: 'dp',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            globalAuthProvider.overrideWith(() => _StubAuthNotifier()),
            companyBrandsProvider.overrideWith((ref) async => const <CompanyBrand>[]),
            agendaPropertiesProvider('agd_withdisc').overrideWith((ref) async => const <AgendaProperty>[]),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: AgendaDetailView(item: withDiscountItem),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(find.text('Sisa Pelunasan'), 300, scrollable: find.byType(Scrollable).first);
      await tester.pumpAndSettle();

      expect(find.text('Diskon (10%)'), findsOneWidget);
      expect(find.text('-Rp 400.000'), findsOneWidget);
      expect(find.text('+Rp 300.000'), findsOneWidget);
      expect(find.text('Rp 3.900.000'), findsOneWidget); // Total: (4jt - 400rb) + 300rb
      expect(find.text('Rp 2.900.000'), findsOneWidget); // Sisa: 3.9jt - 1jt DP

      // Pastikan urutan vertikal: Subtotal -> Diskon -> Transport -> DP -> Sisa
      final subtotalY = tester.getTopLeft(find.text('Subtotal Dekorasi')).dy;
      final discountY = tester.getTopLeft(find.text('Diskon (10%)')).dy;
      final transportY = tester.getTopLeft(find.text('Ongkos Kirim / Transport')).dy;
      final dpY = tester.getTopLeft(find.text('DP Diterima')).dy;
      final sisaY = tester.getTopLeft(find.text('Sisa Pelunasan')).dy;

      expect(subtotalY < discountY, isTrue);
      expect(discountY < transportY, isTrue);
      expect(transportY < dpY, isTrue);
      expect(dpY < sisaY, isTrue);
    });

    testWidgets('AgendaEditView initializes discount, updates live summary, and submits discount payload', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final capturingService = _CapturingAgendaService();
      final item = AgendaItem(
        id: 'agd_edit_1',
        clientName: 'Rian & Nisa',
        clientPhone: '081234567890',
        backdropTitle: 'Engagement',
        eventDateTime: DateTime(2026, 12, 20, 10, 0),
        mapsUrl: '',
        packageId: 'pkg_1',
        packageName: 'Paket Silver',
        packagePrice: 4000000,
        discountType: 'percent',
        discountValue: 10,
        transportFee: 300000,
        dpAmount: 1000000,
        paymentStatus: 'dp',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            globalAuthProvider.overrideWith(() => _StubAuthNotifier()),
            agendaServiceProvider.overrideWithValue(capturingService),
            companyBrandsProvider.overrideWith((ref) async => const <CompanyBrand>[]),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: AgendaEditView(item: item),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Ringkasan Tagihan & Pembayaran'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      // Ringkasan live langsung menampilkan hasil diskon 10% (tanpa memotong transport)
      expect(find.text('Diskon (10%)'), findsOneWidget);
      expect(find.text('-Rp 400.000'), findsOneWidget);
      expect(find.text('+Rp 300.000'), findsOneWidget);
      expect(find.text('Rp 3.900.000'), findsOneWidget);
      expect(find.text('Rp 2.900.000'), findsOneWidget);

      // Simpan Perubahan -> payload harus mengirim discountType & discountValue
      await tester.tap(find.text('Simpan Perubahan'));
      await tester.pumpAndSettle();

      expect(capturingService.lastUpdateArgs, isNotNull);
      expect(capturingService.lastUpdateArgs!['discountType'], 'percent');
      expect(capturingService.lastUpdateArgs!['discountValue'], 10.0);
      expect(capturingService.lastUpdateArgs!['transportFee'], 300000.0);
      expect(capturingService.lastUpdateArgs!['dpAmount'], 1000000.0);
    });
  });
}
