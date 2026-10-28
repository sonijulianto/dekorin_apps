import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dekorin_apps/data/datasources/local/data_preferences.dart';
import 'package:dekorin_apps/domain/models/agenda.dart';
import 'package:dekorin_apps/domain/models/invoice_template.dart';
import 'package:dekorin_apps/domain/models/user.dart';
import 'package:dekorin_apps/ui/features/agenda/views/invoice_pdf_helper.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('id_ID', null);
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await DataPreferences.init();
  });

  group('InvoiceTemplate Enum & Persistence Tests', () {
    test('InvoiceTemplate fromId returns correct enum and defaults correctly', () {
      expect(InvoiceTemplate.fromId('template_modern_navy'), InvoiceTemplate.modernNavy);
      expect(InvoiceTemplate.fromId('template_minimalist_grey'), InvoiceTemplate.minimalistGrey);
      expect(InvoiceTemplate.fromId('unknown_id'), InvoiceTemplate.modernNavy);
      expect(InvoiceTemplate.fromId(null), InvoiceTemplate.modernNavy);
    });

    test('DataPreferences correctly saves and loads selected invoice template', () async {
      expect(DataPreferences.getInvoiceTemplate(), 'template_modern_navy');

      await DataPreferences.setInvoiceTemplate(InvoiceTemplate.minimalistGrey.id);
      expect(DataPreferences.getInvoiceTemplate(), 'template_minimalist_grey');
      expect(InvoiceTemplate.fromId(DataPreferences.getInvoiceTemplate()), InvoiceTemplate.minimalistGrey);

      await DataPreferences.setInvoiceTemplate(InvoiceTemplate.modernNavy.id);
      expect(DataPreferences.getInvoiceTemplate(), 'template_modern_navy');
      expect(InvoiceTemplate.fromId(DataPreferences.getInvoiceTemplate()), InvoiceTemplate.modernNavy);
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
}
