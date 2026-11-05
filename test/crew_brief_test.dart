import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:dekorin_apps/domain/models/agenda.dart';
import 'package:dekorin_apps/domain/models/crew_brief.dart';
import 'package:dekorin_apps/ui/features/agenda/views/crew_brief_form_view.dart';
import 'package:dekorin_apps/ui/features/agenda/views/crew_brief_pdf_helper.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await initializeDateFormatting('id_ID', null);
  });

  final sampleAgenda = AgendaItem(
    id: 'agd_test_01',
    clientName: 'Rian & Sarah',
    backdropTitle: 'The Wedding of Rian & Sarah',
    eventDateTime: DateTime(2026, 11, 14, 9, 0),
    mapsUrl: 'https://maps.google.com/?q=Test',
    packageId: 'pkg_01',
    packageName: 'Paket Rustic Modern',
    modelName: 'Rustic Elegance Special',
    modelWidth: '6 Meter',
    notes: 'Catatan tambahan',
  );

  group('CrewBriefSection Model Tests', () {
    test('Default section has 1 empty note and correct defaults', () {
      final section = CrewBriefSection();
      expect(section.notes.length, 1);
      expect(section.notes.first, '');
      expect(section.hasImage, false);
    });

    test('Section with imageUrl or bytes returns hasImage true', () {
      final section = CrewBriefSection(
        title: 'Area Backdrop',
        imageUrl: 'https://example.com/photo.jpg',
        notes: ['Pasang lampu sorot warm white', 'Standing flower kanan 2'],
      );
      expect(section.hasImage, true);
      expect(section.notes.length, 2);
    });
  });

  group('CrewBriefPdfHelper Generation Tests', () {
    test('generateCrewBriefPdf generates valid non-empty PDF bytes', () async {
      final sections = [
        CrewBriefSection(
          title: 'Area Pelaminan',
          notes: ['Kain ditarik kencang', 'Standing flower 2 pcs'],
        ),
        CrewBriefSection(
          title: 'Area Meja Akad',
          notes: ['Taplak broken white', 'Kursi 6 pcs'],
        ),
      ];

      final pdfBytes = await CrewBriefPdfHelper.generateCrewBriefPdf(
        agenda: sampleAgenda,
        sections: sections,
      );

      expect(pdfBytes, isNotNull);
      expect(pdfBytes.isNotEmpty, true);
      expect(String.fromCharCodes(pdfBytes.take(4)), '%PDF');
    });
  });

  group('CrewBriefFormView Widget Tests', () {
    testWidgets('Renders initial section and allows adding notes & sections', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: CrewBriefFormView(agenda: sampleAgenda),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Memastikan judul screen tampil
      expect(find.text('Buat Lembar Kerja Crew A4'), findsOneWidget);
      expect(find.text('Klien: Rian & Sarah'), findsOneWidget);

      // Seksi awal tampil
      expect(find.text('BAGIAN 1'), findsOneWidget);

      // Coba tambah baris poin catatan
      final addNoteButton = find.text('Tambah Poin');
      expect(addNoteButton, findsOneWidget);
      await tester.tap(addNoteButton);
      await tester.pumpAndSettle();

      // Sekarang ada badge nomor 1 dan 2
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);

      // Coba tambah seksi area baru
      final addSectionButton = find.text('Tambah Bagian / Foto Lain');
      expect(addSectionButton, findsOneWidget);
      await tester.tap(addSectionButton);
      await tester.pumpAndSettle();

      // Sekarang ada BAGIAN 1 dan BAGIAN 2
      expect(find.text('BAGIAN 1'), findsOneWidget);
      expect(find.text('BAGIAN 2'), findsOneWidget);
    });
  });
}
