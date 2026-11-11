import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dekorin_apps/config/theme/app_theme.dart';
import 'package:dekorin_apps/data/datasources/remote/api_endpoint.dart';
import 'package:dekorin_apps/domain/models/invitation.dart';
import 'package:dekorin_apps/ui/features/invitation/views/invitation_generator_view.dart';
import 'package:dekorin_apps/ui/features/invitation/views/invitation_template_picker_view.dart';
import 'package:dekorin_apps/ui/features/invitation/views/invitation_visual_editor_view.dart';

void main() {
  group('Invitation Flow & Template Tests', () {
    test('InvitationTemplate has 6 active templates: ta17, jawa3, jawa2, ta3, pn4, and ultah1', () {
      final templates = InvitationTemplate.all;
      expect(templates.length, 6);

      final ids = templates.map((t) => t['id'] as String).toList();
      expect(ids, containsAll([
        InvitationTemplate.ta17,
        InvitationTemplate.jawa3,
        InvitationTemplate.jawa2,
        InvitationTemplate.ta3,
        InvitationTemplate.pn4,
        InvitationTemplate.ultah1,
      ]));

      // Fallback test
      expect(InvitationTemplate.getById('unknown_id')['id'], InvitationTemplate.ta17);
      expect(InvitationTemplate.getById('ta17')['name'], 'Ocean Blossom TA17');
      expect(InvitationTemplate.getById('jawa3')['name'], 'Art Jawa Coklat 3');
      expect(InvitationTemplate.getById('jawa2')['name'], 'Art Jawa Biru 2');
      expect(InvitationTemplate.getById('ta3')['name'], 'Sakura Blossom TA3');
      expect(InvitationTemplate.getById('pn4')['name'], 'Monochrome PN4');
      expect(InvitationTemplate.getById('ultah1')['name'], 'Pita & Bola Disko');
      expect(InvitationTemplate.getById('ultah1')['category'], 'birthday');
    });

    test('InvitationEventCategory contains all event types and getAvailableCategories returns wedding, khitan & birthday', () {
      final categories = InvitationEventCategory.all;
      expect(categories.length, greaterThanOrEqualTo(8));

      final ids = categories.map((c) => c['id'] as String).toList();
      expect(ids, containsAll(['wedding', 'khitan', 'birthday', 'engagement', 'aqiqah']));

      // Available categories derived from templates: wedding, khitan (jawa3/jawa2), dan birthday (ultah1)
      final available = InvitationEventCategory.getAvailableCategories();
      expect(available.length, 3);
      final availableIds = available.map((c) => c['id']).toList();
      expect(availableIds, containsAll(['wedding', 'khitan', 'birthday']));

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

      // Pastikan tombol 'Lihat Preview' tersedia di setiap kartu template
      expect(find.text('Lihat Preview'), findsWidgets);
    });

    test('ApiEndpoint.getInvitationTemplatePreviewUrl generates valid preview url', () {
      final urlTa17 = ApiEndpoint.getInvitationTemplatePreviewUrl('ta17');
      expect(urlTa17, contains('/preview/ta17'));
      expect(urlTa17, contains('preview=1'));

      final urlWithSlug = ApiEndpoint.getInvitationTemplatePreviewUrl('pn4', 'bagas-zulia');
      expect(urlWithSlug, contains('/preview/pn4'));
      expect(urlWithSlug, contains('slug=bagas-zulia'));
      expect(urlWithSlug, contains('preview=1'));
    });

    testWidgets('InvitationGeneratorView renders and adds quick guest without layout errors', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const invitation = InvitationItem(
        id: 'inv-1',
        slug: 'bagas-zulia',
        title: 'The Wedding of Bagas & Zulia',
        groomName: 'Bagas',
        groomNickname: 'Bagas',
        brideName: 'Zulia',
        brideNickname: 'Zulia',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const InvitationGeneratorView(invitation: invitation),
        ),
      );
      await tester.pumpAndSettle();

      final addBtn = find.text('Tambah');
      await tester.scrollUntilVisible(
        addBtn,
        300.0,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(addBtn, findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextField, 'Ketik nama tamu lalu klik Tambah...'),
        'Budi Santoso',
      );
      await tester.tap(addBtn);
      await tester.pumpAndSettle();

      expect(find.text('Budi Santoso'), findsOneWidget);
    });

    test('ApiEndpoint.getInvitationVisualEditorUrl generates ?preview=1&edit=1 url', () {
      final urlDefault = ApiEndpoint.getInvitationVisualEditorUrl('bagas-zulia');
      expect(urlDefault, contains('/bagas-zulia'));
      expect(urlDefault, contains('preview=1'));
      expect(urlDefault, contains('edit=1'));
      expect(urlDefault, isNot(contains('template=')));

      final urlOverride = ApiEndpoint.getInvitationVisualEditorUrl(
        'bagas-zulia',
        templateOverride: 'pn4',
      );
      expect(urlOverride, contains('/bagas-zulia'));
      expect(urlOverride, contains('template=pn4'));
      expect(urlOverride, contains('edit=1'));
    });

    testWidgets('InvitationVisualEditorView renders cleanly without overflow on headless host and validates pn4 save', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const invitation = InvitationItem(
        id: 'inv-ve-1',
        slug: 'bagas-zulia',
        title: 'The Wedding of Bagas & Zulia',
        template: InvitationTemplate.pn4,
        groomName: 'Bagas',
        groomNickname: 'Bagas',
        brideName: 'Zulia',
        brideNickname: 'Zulia',
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const InvitationVisualEditorView(invitation: invitation),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Visual Editor Undangan'), findsOneWidget);
      expect(find.text('Simpan'), findsOneWidget);
      expect(find.text('Pratinjau Bersih'), findsOneWidget);
      expect(find.text('Buka Mode Form'), findsOneWidget);

      // Coba simpan Monochrome tanpa foto wajib -> harus menampilkan validasi aman
      await tester.tap(find.text('Simpan'));
      await tester.pump();
      expect(
        find.text('Foto Sampul Utama wajib diunggah untuk tema Monochrome (*Mandatory)'),
        findsOneWidget,
      );
    });
  });
}
