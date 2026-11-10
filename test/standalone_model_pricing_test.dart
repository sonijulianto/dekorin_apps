import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:dekorin_apps/config/theme/app_theme.dart';
import 'package:dekorin_apps/data/services/master_service.dart';
import 'package:dekorin_apps/domain/models/agenda.dart';
import 'package:dekorin_apps/domain/models/decoration_model.dart';
import 'package:dekorin_apps/domain/models/decoration_package.dart';
import 'package:dekorin_apps/ui/features/agenda/views/invoice_pdf_helper.dart';
import 'package:dekorin_apps/ui/features/agenda/views/model_picker_screen.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  group('Standalone Model AgendaItem & Invoice', () {
    test('AgendaItem flags and total price work when no package is selected', () {
      final standalone = AgendaItem(
        id: 'agd_standalone',
        clientName: 'Rian & Nisa',
        backdropTitle: 'Wedding Rian & Nisa',
        eventDateTime: DateTime(2026, 11, 20, 10, 0),
        mapsUrl: '',
        packageId: '',
        packageName: 'Belum Dipilih',
        packagePrice: 0,
        modelId: 'mdl_01',
        modelName: 'Rustic Arch 3m',
        modelWidth: '3 Meter',
        modelAdditionalPrice: 2000000,
        transportFee: 250000,
      );

      expect(standalone.hasPackage, false);
      expect(standalone.isStandaloneModel, true);
      expect(standalone.displayPackageOrModelTitle, 'Rustic Arch 3m');
      expect(standalone.calculatedTotalPrice, 2250000);

      final pdfItems = InvoicePdfHelper.buildPrimaryDecorationItems(standalone, 0.0);
      expect(pdfItems.length, 1);
      expect(pdfItems.first.name, 'Rustic Arch 3m');
      expect(pdfItems.first.subtitle, '');
      expect(pdfItems.first.unitPrice, 2000000);
      expect(pdfItems.first.totalPrice, 2000000);

      final pdfItemsUpper = InvoicePdfHelper.buildPrimaryDecorationItems(
        standalone,
        0.0,
        uppercase: true,
      );
      expect(pdfItemsUpper.length, 1);
      expect(pdfItemsUpper.first.name, 'RUSTIC ARCH 3M');
      expect(pdfItemsUpper.first.subtitle, '');
    });

    test('AgendaItem with package keeps package + upgrade model rows', () {
      final withPkg = AgendaItem(
        id: 'agd_pkg',
        clientName: 'Siti & Budi',
        backdropTitle: 'The Wedding',
        eventDateTime: DateTime(2026, 11, 22, 10, 0),
        mapsUrl: '',
        packageId: 'pkg_gold',
        packageName: 'Paket Gold',
        packagePrice: 4500000,
        modelId: 'mdl_02',
        modelName: 'Modern Hexagon',
        modelWidth: '4 Meter',
        modelAdditionalPrice: 300000,
      );

      expect(withPkg.hasPackage, true);
      expect(withPkg.isStandaloneModel, false);
      expect(withPkg.displayPackageOrModelTitle, 'Paket Gold');
      expect(withPkg.calculatedTotalPrice, 4800000);

      final pdfItems = InvoicePdfHelper.buildPrimaryDecorationItems(withPkg, 4500000);
      expect(pdfItems.length, 2);
      expect(pdfItems[0].name, 'Paket Gold');
      expect(pdfItems[0].totalPrice, 4500000);
      expect(pdfItems[1].name, 'Upgrade Model: Modern Hexagon');
      expect(pdfItems[1].totalPrice, 300000);
    });
  });

  group('ModelPickerScreen contextual pricing', () {
    const sampleModels = [
      DecorationModel(
        id: 'mdl_01',
        name: 'Rustic Arch 3m',
        width: '3 Meter',
        price: 2000000,
      ),
    ];

    testWidgets('without package returns model.price as selected price', (tester) async {
      SelectedModelResult? poppedResult;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            decorationModelsProvider.overrideWith((ref) async => sampleModels),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      poppedResult = await Navigator.of(context).push<SelectedModelResult>(
                        MaterialPageRoute(
                          builder: (_) => const ModelPickerScreen(package: null),
                        ),
                      );
                    },
                    child: const Text('Open Picker'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Picker'));
      await tester.pumpAndSettle();

      expect(find.text('Harga Model: Rp 2.000.000'), findsOneWidget);
      await tester.tap(find.text('Pilih Model Ini'));
      await tester.pumpAndSettle();

      expect(poppedResult, isNotNull);
      expect(poppedResult!.model?.id, 'mdl_01');
      expect(poppedResult!.additionalPrice, 2000000);
    });

    testWidgets('with package returns package additionalPrice instead of model base price', (tester) async {
      SelectedModelResult? poppedResult;
      const pkg = DecorationPackage(
        id: 'pkg_01',
        name: 'Paket Silver',
        description: 'Paket lengkap',
        basePrice: 3500000,
        packageModels: [
          PackageModelItem(
            id: 'pm_1',
            packageId: 'pkg_01',
            decorationModelId: 'mdl_01',
            additionalPrice: 350000,
            decorationModel: DecorationModel(
              id: 'mdl_01',
              name: 'Rustic Arch 3m',
              width: '3 Meter',
              price: 2000000,
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            decorationModelsProvider.overrideWith((ref) async => sampleModels),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      poppedResult = await Navigator.of(context).push<SelectedModelResult>(
                        MaterialPageRoute(
                          builder: (_) => const ModelPickerScreen(package: pkg),
                        ),
                      );
                    },
                    child: const Text('Open Picker'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Picker'));
      await tester.pumpAndSettle();

      expect(find.text('Tambahan Biaya: +Rp 350.000'), findsOneWidget);
      await tester.tap(find.text('Pilih Model Ini'));
      await tester.pumpAndSettle();

      expect(poppedResult, isNotNull);
      expect(poppedResult!.model?.id, 'mdl_01');
      expect(poppedResult!.additionalPrice, 350000);
    });
  });
}
