import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:dekorin_apps/config/theme/app_theme.dart';
import 'package:dekorin_apps/data/services/company_service.dart';
import 'package:dekorin_apps/data/services/master_service.dart';
import 'package:dekorin_apps/data/services/property_service.dart';
import 'package:dekorin_apps/domain/models/company_profile.dart';
import 'package:dekorin_apps/domain/models/decoration_model.dart';
import 'package:dekorin_apps/domain/models/decoration_package.dart';
import 'package:dekorin_apps/domain/models/property.dart';
import 'package:dekorin_apps/domain/models/user.dart';
import 'package:dekorin_apps/ui/core/widgets/loading_overlay_dialog.dart';
import 'package:dekorin_apps/ui/features/login/view_models/global_auth_provider.dart';
import 'package:dekorin_apps/ui/features/master/views/manage_decoration_models_view.dart';
import 'package:dekorin_apps/ui/features/master/views/manage_packages_view.dart';
import 'package:dekorin_apps/ui/features/master/views/manage_properties_view.dart';

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

class _FakeMasterService extends MasterService {
  _FakeMasterService({
    this.models = const [],
    this.packages = const [],
    this.delayedModelsCompleter,
  });

  final List<DecorationModel> models;
  final List<DecorationPackage> packages;
  final Completer<List<DecorationModel>>? delayedModelsCompleter;

  @override
  Future<List<DecorationModel>> getDecorationModels() async {
    if (delayedModelsCompleter != null) {
      return delayedModelsCompleter!.future;
    }
    return models;
  }

  @override
  Future<List<DecorationPackage>> getPackages() async {
    return packages;
  }
}

class _FakeCompanyService extends CompanyService {
  _FakeCompanyService({this.brandsCompleter});

  final Completer<List<CompanyBrand>>? brandsCompleter;

  @override
  Future<List<CompanyBrand>> getCompanyBrands() async {
    if (brandsCompleter != null) {
      return brandsCompleter!.future;
    }
    return const [];
  }
}

class _FakePropertyService extends PropertyService {
  _FakePropertyService({
    this.propertiesCompleter,
    this.createCompleter,
  });

  final Completer<List<Property>>? propertiesCompleter;
  final Completer<Property>? createCompleter;
  int createCallCount = 0;

  @override
  Future<List<Property>> getProperties({String? type, String? category, String? search}) async {
    if (propertiesCompleter != null) {
      return propertiesCompleter!.future;
    }
    return const [];
  }

  @override
  Future<Property> createProperty({
    required String name,
    required String category,
    required String type,
    bool? trackStock,
    required int totalStock,
    String unit = 'pcs',
    String notes = '',
    String imageUrl = '',
  }) async {
    createCallCount++;
    if (createCompleter != null) {
      return createCompleter!.future;
    }
    return Property(
      id: 'prop_new',
      name: name,
      category: category,
      type: type,
      trackStock: trackStock ?? true,
      totalStock: totalStock,
      unit: unit,
      notes: notes,
    );
  }
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  testWidgets('DekorinLoadingDialog.run shows loading overlay, blocks repeated taps, and dismisses cleanly',
      (tester) async {
    int triggerCount = 0;
    final completer = Completer<String>();
    String? result;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  triggerCount++;
                  result = await DekorinLoadingDialog.run(
                    context,
                    message: 'Memproses data...',
                    task: () => completer.future,
                  );
                },
                child: const Text('Jalankan'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Jalankan'));
    await tester.pump();

    // Loading dialog immediately visible
    expect(find.text('Memproses data...'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(triggerCount, 1);

    // Tap behind barrier — must not trigger button again
    await tester.tap(find.text('Jalankan'), warnIfMissed: false);
    await tester.pump();
    expect(triggerCount, 1);

    completer.complete('ok');
    await tester.pumpAndSettle();

    expect(find.text('Memproses data...'), findsNothing);
    expect(result, 'ok');
  });

  testWidgets('DekorinConfirmActionDialog shows spinner while processing and blocks double confirm',
      (tester) async {
    int confirmCalls = 0;
    final completer = Completer<void>();

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () {
                  DekorinConfirmActionDialog.show(
                    context,
                    title: 'Hapus Item?',
                    message: 'Konfirmasi hapus item',
                    confirmLabel: 'Hapus',
                    onConfirm: () {
                      confirmCalls++;
                      return completer.future;
                    },
                  );
                },
                child: const Text('Buka Dialog'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Buka Dialog'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Hapus'));
    await tester.pump();

    // Spinner appears inside dialog, confirm called once
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(confirmCalls, 1);

    // Attempting to tap Batal or ElevatedButton while processing does nothing
    await tester.tap(find.text('Batal'));
    await tester.pump();
    expect(find.text('Hapus Item?'), findsOneWidget);
    expect(confirmCalls, 1);

    completer.complete();
    await tester.pumpAndSettle();

    expect(find.text('Hapus Item?'), findsNothing);
  });

  testWidgets('ManageDecorationModelsView opens edit sheet immediately with loading indicator before data arrives',
      (tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final brandsCompleter = Completer<List<CompanyBrand>>();
    final propsCompleter = Completer<List<Property>>();

    final fakeMaster = _FakeMasterService(
      models: const [
        DecorationModel(
          id: 'mdl_1',
          name: 'Rustic Arch Luxury',
          width: '4 Meter',
          price: 2500000,
          description: 'Arch kayu mewah',
        ),
      ],
    );
    final fakeCompany = _FakeCompanyService(brandsCompleter: brandsCompleter);
    final fakeProperty = _FakePropertyService(propertiesCompleter: propsCompleter);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          globalAuthProvider.overrideWith(() => _FakeAuthNotifier()),
          masterServiceProvider.overrideWithValue(fakeMaster),
          companyServiceProvider.overrideWithValue(fakeCompany),
          propertyServiceProvider.overrideWithValue(fakeProperty),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ManageDecorationModelsView(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Rustic Arch Luxury'), findsOneWidget);

    // Open menu on model card & tap Edit
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // Bottom sheet must open IMMEDIATELY showing loading state while API is pending!
    expect(find.text('Edit Model Dekorasi'), findsOneWidget);
    expect(find.text('Memuat data model...'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Resolve brands & properties
    brandsCompleter.complete(const []);
    propsCompleter.complete(const [
      Property(id: 'p1', name: 'Kursi Pelaminan', category: 'Furnitur', type: 'property', totalStock: 4),
    ]);
    await tester.pumpAndSettle();

    // Loading disappears and form fields appear with existing model data
    expect(find.text('Memuat data model...'), findsNothing);
    expect(find.text('Rustic Arch Luxury'), findsWidgets);
    expect(find.text('Simpan Perubahan'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ManagePackagesView opens edit sheet immediately with loading indicator before models arrive',
      (tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final modelsCompleter = Completer<List<DecorationModel>>();
    final brandsCompleter = Completer<List<CompanyBrand>>();

    final fakeMaster = _FakeMasterService(
      packages: const [
        DecorationPackage(
          id: 'pkg_1',
          name: 'Paket Platinum Akad',
          description: 'Dekorasi lengkap',
          basePrice: 5000000,
        ),
      ],
      delayedModelsCompleter: modelsCompleter,
    );
    final fakeCompany = _FakeCompanyService(brandsCompleter: brandsCompleter);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          globalAuthProvider.overrideWith(() => _FakeAuthNotifier()),
          masterServiceProvider.overrideWithValue(fakeMaster),
          companyServiceProvider.overrideWithValue(fakeCompany),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ManagePackagesView(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Paket Platinum Akad'), findsOneWidget);

    // Open menu on package card & tap Edit
    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    // Bottom sheet opens immediately with loading state
    expect(find.text('Edit Paket Dekorasi'), findsOneWidget);
    expect(find.text('Memuat data paket...'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    modelsCompleter.complete(const []);
    brandsCompleter.complete(const []);
    await tester.pumpAndSettle();

    expect(find.text('Memuat data paket...'), findsNothing);
    expect(find.text('Simpan Perubahan'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ManagePropertiesView submit button shows spinner and prevents duplicate submit',
      (tester) async {
    tester.view.physicalSize = const Size(412, 915);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final createCompleter = Completer<Property>();
    final fakeProperty = _FakePropertyService(createCompleter: createCompleter);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          globalAuthProvider.overrideWith(() => _FakeAuthNotifier()),
          propertyServiceProvider.overrideWithValue(fakeProperty),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ManagePropertiesView(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Open Add Property sheet
    await tester.tap(find.text('Tambah Properti'));
    await tester.pumpAndSettle();

    // Fill required property name
    await tester.enterText(find.byType(TextFormField).first, 'Vas Bunga Gold');
    await tester.pump();

    // Tap Submit
    final submitBtnFinder = find.text('Tambah ke Inventaris');
    await tester.ensureVisible(submitBtnFinder);
    await tester.tap(submitBtnFinder);
    await tester.pump();

    // Spinner shown & createProperty called once
    expect(fakeProperty.createCallCount, 1);
    expect(find.text('Tambah ke Inventaris'), findsNothing);

    // Tapping ElevatedButton again while submitting does NOT call createProperty again
    final elevatedBtn = find.byType(ElevatedButton).last;
    await tester.tap(elevatedBtn);
    await tester.pump();
    expect(fakeProperty.createCallCount, 1);

    createCompleter.complete(
      const Property(id: 'p_new', name: 'Vas Bunga Gold', category: 'Lainnya', type: 'property', totalStock: 1),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
