import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dekorin_apps/domain/models/invitation.dart';
import 'package:dekorin_apps/ui/features/invitation/views/invitation_template_picker_view.dart';

void main() {
  group('Invitation Flow & Template Tests', () {
    test('InvitationTemplate has 4 active templates: ta17, jawa3, ta3, and pn4', () {
      final templates = InvitationTemplate.all;
      expect(templates.length, 4);

      final ids = templates.map((t) => t['id'] as String).toList();
      expect(ids, containsAll([
        InvitationTemplate.ta17,
        InvitationTemplate.jawa3,
        InvitationTemplate.ta3,
        InvitationTemplate.pn4,
      ]));

      // Pastikan semua template aktif saat ini mendukung kategori wedding
      for (final tmpl in templates) {
        expect(tmpl['category'], 'wedding');
        expect(tmpl['supportedCategories'], contains('wedding'));
      }

      // Fallback test
      expect(InvitationTemplate.getById('unknown_id')['id'], InvitationTemplate.ta17);
      expect(InvitationTemplate.getById('ta17')['name'], 'Ocean Blossom TA17');
      expect(InvitationTemplate.getById('jawa3')['name'], 'Art Jawa Coklat 3');
      expect(InvitationTemplate.getById('ta3')['name'], 'Sakura Blossom TA3');
      expect(InvitationTemplate.getById('pn4')['name'], 'Monochrome PN4');
    });

    test('InvitationEventCategory contains all event types and getAvailableCategories returns wedding & khitan', () {
      final categories = InvitationEventCategory.all;
      expect(categories.length, greaterThanOrEqualTo(8));

      final ids = categories.map((c) => c['id'] as String).toList();
      expect(ids, containsAll(['wedding', 'khitan', 'birthday', 'engagement', 'aqiqah']));

      // Available categories derived from templates: saat ini wedding dan khitan (didukung jawa3)
      final available = InvitationEventCategory.getAvailableCategories();
      expect(available.length, 2);
      final availableIds = available.map((c) => c['id']).toList();
      expect(availableIds, containsAll(['wedding', 'khitan']));

      expect(InvitationEventCategory.getById('khitan')['shortName'], 'Khitanan');
      expect(InvitationEventCategory.getById('birthday')['shortName'], 'Ulang Tahun');
      expect(InvitationEventCategory.getById('non_existent')['id'], 'wedding');
    });

    testWidgets('InvitationTemplatePickerView renders template list and allows searching', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const MaterialApp(
          home: InvitationTemplatePickerView(
            initialTemplateId: 'ta17',
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Memastikan ketiga template tampil pada viewport penuh
      expect(find.text('Ocean Blossom TA17'), findsOneWidget);
      expect(find.text('Sakura Blossom TA3'), findsOneWidget);
      expect(find.text('Monochrome PN4'), findsOneWidget);

      // Cek pencarian 'monochrome'
      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);

      await tester.enterText(searchField, 'monochrome');
      await tester.pumpAndSettle();

      expect(find.text('Monochrome PN4'), findsOneWidget);
      expect(find.text('Ocean Blossom TA17'), findsNothing);
      expect(find.text('Sakura Blossom TA3'), findsNothing);

      // Hapus pencarian
      await tester.enterText(searchField, '');
      await tester.pumpAndSettle();

      expect(find.text('Ocean Blossom TA17'), findsOneWidget);
      expect(find.text('Sakura Blossom TA3'), findsOneWidget);
      expect(find.text('Monochrome PN4'), findsOneWidget);
    });
  });
}
