import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dekorin_apps/config/theme/app_theme.dart';
import 'package:dekorin_apps/domain/models/property.dart';
import 'package:dekorin_apps/ui/features/master/widgets/multi_select_property_sheet.dart';

void main() {
  testWidgets('MultiSelectPropertySheet renders and interacts without layout errors on narrow screens',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final properties = [
      const Property(
        id: '1',
        name: 'Rangka Besi Pelaminan Lebar 6 Meter',
        category: 'Rangka & Struktur Utama',
        type: 'property',
        totalStock: 15,
        unit: 'paket',
      ),
      const Property(
        id: '2',
        name: 'Lampu Sorot LED Warm White',
        category: 'Pencahayaan',
        type: 'property',
        totalStock: 10,
        unit: 'pcs',
      ),
      const Property(
        id: '3',
        name: 'Tang Kombinasi Heavy Duty',
        category: 'Alat Kerja Teknisi',
        type: 'tool',
        trackStock: false,
        totalStock: 2,
        unit: 'pcs',
      ),
    ];

    List<SelectedPropertyItem>? returnedItems;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        builder: (context, child) => GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: child,
        ),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  returnedItems = await MultiSelectPropertySheet.show(
                    context,
                    allProperties: properties,
                    initiallySelectedPropertyIds: const {'1'},
                    initialQuantities: const {'1': 2},
                  );
                },
                child: const Text('Open Sheet'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Sheet'));
    await tester.pumpAndSettle();

    expect(find.text('Pilih Barang Sekaligus'), findsOneWidget);
    expect(find.text('Rangka Besi Pelaminan Lebar 6 Meter'), findsOneWidget);
    expect(find.text('Terapkan (1 Barang)'), findsOneWidget);

    // Filter to tools only and select item 3
    await tester.ensureVisible(find.text('🛠️ Alat'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('🛠️ Alat'));
    await tester.pumpAndSettle();
    expect(find.text('Tang Kombinasi Heavy Duty'), findsOneWidget);
    expect(find.text('Rangka Besi Pelaminan Lebar 6 Meter'), findsNothing);

    await tester.tap(find.text('Tang Kombinasi Heavy Duty'));
    await tester.pumpAndSettle();
    expect(find.text('Terapkan (2 Barang)'), findsOneWidget);

    // Increment quantity for item 3
    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    expect(find.text('2'), findsOneWidget);

    // Apply selection and verify returned list
    await tester.tap(find.text('Terapkan (2 Barang)'));
    await tester.pumpAndSettle();

    expect(returnedItems, isNotNull);
    expect(returnedItems!.length, 2);
    expect(returnedItems!.map((e) => e.property.id), containsAll(['1', '3']));
  });
}
