import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dekorin_apps/data/datasources/local/data_preferences.dart';
import 'package:dekorin_apps/domain/models/agenda.dart';
import 'package:dekorin_apps/domain/models/company_profile.dart';
import 'package:dekorin_apps/domain/models/invoice_template.dart';
import 'package:dekorin_apps/domain/models/user.dart';
import 'package:dekorin_apps/ui/features/agenda/view_models/invoice_template_provider.dart';
import 'package:dekorin_apps/ui/features/agenda/views/invoice_pdf_helper.dart';
import 'package:dekorin_apps/ui/features/agenda/views/invoice_preview_view.dart';
import 'package:dekorin_apps/ui/features/agenda/views/invoice_template_setting_view.dart';
import 'package:dekorin_apps/data/services/company_service.dart';
import 'package:dekorin_apps/ui/features/login/view_models/global_auth_provider.dart';

class _StubAuthNotifier extends AuthNotifier {
  _StubAuthNotifier(this._user);
  final User? _user;

  @override
  Future<User?> build() async => _user;
}

class _StubCompanyService extends CompanyService {
  final List<(String, String)> updatedCalls = [];
  String _mainTemplate = InvoiceTemplate.minimalistGrey.id;
  String _brandTemplate = InvoiceTemplate.modernNavy.id;

  @override
  Future<List<CompanyBrand>> getCompanyBrands() async => const [
        CompanyBrand(id: 'brd_custom', name: 'Sub Brand Elegan'),
      ];

  @override
  Future<CompanyInvoiceTemplateConfig> getInvoiceTemplate({String brandId = ''}) async {
    return CompanyInvoiceTemplateConfig(
      brandId: brandId,
      invoiceTemplate: InvoiceTemplate.fromId(brandId == 'brd_custom' ? _brandTemplate : _mainTemplate),
      companyInvoiceTemplate: InvoiceTemplate.fromId(_mainTemplate),
      brandTemplates: {
        '': InvoiceTemplate.fromId(_mainTemplate),
        'brd_custom': InvoiceTemplate.fromId(_brandTemplate),
      },
      inheritedBrandIds: const {},
    );
  }

  @override
  Future<CompanyInvoiceTemplateConfig> updateInvoiceTemplate({
    String brandId = '',
    required String templateId,
  }) async {
    updatedCalls.add((brandId, templateId));
    if (brandId == 'brd_custom') {
      _brandTemplate = templateId;
    } else {
      _mainTemplate = templateId;
    }
    return getInvoiceTemplate(brandId: brandId);
  }
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('id_ID', null);
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await DataPreferences.init();
  });

  group('InvoiceTemplate Enum & Server Config Tests', () {
    test('InvoiceTemplate fromId returns correct enum and defaults correctly', () {
      expect(InvoiceTemplate.fromId('template_modern_navy'), InvoiceTemplate.modernNavy);
      expect(InvoiceTemplate.fromId('template_minimalist_grey'), InvoiceTemplate.minimalistGrey);
      expect(InvoiceTemplate.fromId('unknown_id'), InvoiceTemplate.modernNavy);
      expect(InvoiceTemplate.fromId(null), InvoiceTemplate.modernNavy);
    });

    test('CompanyInvoiceTemplateConfig parses brand_templates and inherited_brands', () {
      final config = CompanyInvoiceTemplateConfig.fromJson({
        'brand_id': 'brd_1',
        'invoice_template': 'template_minimalist_grey',
        'company_invoice_template': 'template_modern_navy',
        'is_inherited': false,
        'brand_templates': {
          '': 'template_modern_navy',
          'brd_1': 'template_minimalist_grey',
          'brd_2': 'template_modern_navy',
        },
        'inherited_brands': ['brd_2'],
      });

      expect(config.brandId, 'brd_1');
      expect(config.invoiceTemplate, InvoiceTemplate.minimalistGrey);
      expect(config.companyInvoiceTemplate, InvoiceTemplate.modernNavy);
      expect(config.isInherited, isFalse);
      expect(config.brandTemplates[''], InvoiceTemplate.modernNavy);
      expect(config.brandTemplates['brd_1'], InvoiceTemplate.minimalistGrey);
      expect(config.inheritedBrandIds, contains('brd_2'));
    });

    test('InvoiceTemplateState resolves per-brand template and inheritance correctly', () {
      const state = InvoiceTemplateState(
        defaultTemplate: InvoiceTemplate.minimalistGrey,
        brandTemplates: {
          '': InvoiceTemplate.minimalistGrey,
          'brd_custom': InvoiceTemplate.modernNavy,
        },
        inheritedBrandIds: {'brd_inherited'},
      );

      expect(state.templateForBrand(''), InvoiceTemplate.minimalistGrey);
      expect(state.templateForBrand('brd_custom'), InvoiceTemplate.modernNavy);
      expect(state.templateForBrand('brd_inherited'), InvoiceTemplate.minimalistGrey);
      expect(state.isBrandInherited(''), isFalse);
      expect(state.isBrandInherited('brd_custom'), isFalse);
      expect(state.isBrandInherited('brd_inherited'), isTrue);
    });
  });

  group('InvoicePdfHelper PDF Generation Tests', () {
    final sampleAgenda = AgendaItem(
      id: 'fb-001',
      clientName: 'Juwita',
      clientPhone: '0895-1678-9565',
      eventDateTime: DateTime(2026, 10, 21),
      packageId: 'pkg_platinum',
      packageName: 'Backdrop Platinum',
      packagePrice: 1100000,
      transportFee: 400000,
      dpAmount: 200000,
      modelName: 'Platinum Minimalis',
      modelWidth: '3 Meter',
      notes: '[Item Tambahan / Addon]:\n- Lighting Spotlight x2 (50.000 = 100.000)',
      backdropTitle: 'Wedding Juwita',
      mapsUrl: 'Jl. Mayor Oking Jaya Atmaja, Ciriung - Cibinong, Kab Bogor',
    );

    const sampleUser = User(
      id: 'usr_01',
      name: 'Soni Julianto',
      companyName: 'Family Backdrop',
      companyPhone: '0895 1678 9565',
      companyEmail: 'sonijulianto@gmail.com',
      companyAddress: 'Jl. Mayor oking jaya atmaja\nCiriung - Cibinong, Kab Bogor',
      companyBankInfo: 'Nama : Soni Julianto\nNo Rek (BCA) : 5720732931\nNo Rek (BRI) : 144801005406501',
      companyInvoiceTemplate: 'template_minimalist_grey',
    );

    test('generateInvoicePdf generates valid PDF bytes for Template 1 (Modern Navy & Gold)', () async {
      final pdfBytes = await InvoicePdfHelper.generateInvoicePdf(
        sampleAgenda,
        companyUser: sampleUser,
        template: InvoiceTemplate.modernNavy,
      );

      expect(pdfBytes, isNotNull);
      expect(pdfBytes.isNotEmpty, isTrue);
      // PDF file magic header (%PDF)
      expect(pdfBytes[0], 0x25); // %
      expect(pdfBytes[1], 0x50); // P
      expect(pdfBytes[2], 0x44); // D
      expect(pdfBytes[3], 0x46); // F
    });

    test('generateInvoicePdf generates valid PDF bytes for Template 2 (Minimalist Modern Grey)', () async {
      final pdfBytes = await InvoicePdfHelper.generateInvoicePdf(
        sampleAgenda,
        companyUser: sampleUser,
        template: InvoiceTemplate.minimalistGrey,
      );

      expect(pdfBytes, isNotNull);
      expect(pdfBytes.isNotEmpty, isTrue);
      // PDF file magic header (%PDF)
      expect(pdfBytes[0], 0x25); // %
      expect(pdfBytes[1], 0x50); // P
      expect(pdfBytes[2], 0x44); // D
      expect(pdfBytes[3], 0x46); // F
    });
  });

  group('InvoicePreviewView & Setting UI Rules', () {
    testWidgets('InvoicePreviewView does NOT render Template switcher button', (tester) async {
      final agenda = AgendaItem(
        id: 'agd_test',
        clientName: 'Rian & Nisa',
        backdropTitle: 'Wedding Rian & Nisa',
        mapsUrl: 'Jakarta',
        packageId: 'pkg_01',
        eventDateTime: DateTime(2026, 11, 20),
        packageName: 'Paket Akad',
      );
      const user = User(
        id: 'usr_admin',
        name: 'Admin',
        role: 'admin',
        companyId: 'cmp_1',
        companyName: 'Dekor Test',
        companyInvoiceTemplate: 'template_minimalist_grey',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            globalAuthProvider.overrideWith(() => _StubAuthNotifier(user)),
            companyServiceProvider.overrideWithValue(_StubCompanyService()),
          ],
          child: MaterialApp(
            home: InvoicePreviewView(
              agenda: agenda,
              forcedTemplate: InvoiceTemplate.minimalistGrey,
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Template'), findsNothing);
      expect(find.byIcon(Icons.style_outlined), findsNothing);
    });

    testWidgets('InvoiceTemplateSettingView allows setting different templates per brand in DB', (tester) async {
      final stubService = _StubCompanyService();
      const user = User(
        id: 'usr_admin',
        name: 'Admin',
        role: 'admin',
        companyId: 'cmp_1',
        companyName: 'Dekor Utama',
        companyInvoiceTemplate: 'template_minimalist_grey',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            globalAuthProvider.overrideWith(() => _StubAuthNotifier(user)),
            companyServiceProvider.overrideWithValue(stubService),
          ],
          child: const MaterialApp(
            home: InvoiceTemplateSettingView(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Brand Utama & Sub-brand chips rendered
      expect(find.text('Dekor Utama (Utama)'), findsOneWidget);
      expect(find.text('Sub Brand Elegan'), findsOneWidget);

      // Switch to Sub Brand Elegan (currently modernNavy -> minimalistGrey has 'Pilih Template' button)
      await tester.tap(find.text('Sub Brand Elegan'));
      await tester.pumpAndSettle();

      // Scroll down to 'Pilih Template' button on Minimalist Modern Grey card and tap it
      await tester.scrollUntilVisible(
        find.text('Pilih Template'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();

      final selectBtn = find.widgetWithText(ElevatedButton, 'Pilih Template');
      expect(selectBtn, findsOneWidget);
      await tester.tap(selectBtn);
      await tester.pumpAndSettle();

      expect(stubService.updatedCalls, [('brd_custom', 'template_minimalist_grey')]);
    });
  });
}
