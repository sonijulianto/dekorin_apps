import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:dekorin_apps/config/theme/app_theme.dart';
import 'package:dekorin_apps/data/services/company_service.dart';
import 'package:dekorin_apps/domain/models/company_profile.dart';
import 'package:dekorin_apps/domain/models/user.dart';
import 'package:dekorin_apps/ui/features/agenda/views/create_agenda_sheet.dart';
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

Widget _buildModalLauncherApp({bool useSafeArea = true}) {
  return ProviderScope(
    overrides: [
      globalAuthProvider.overrideWith(() => _StubAuthNotifier()),
      companyBrandsProvider.overrideWith((ref) async => const <CompanyBrand>[]),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () {
                showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: useSafeArea,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const CreateAgendaSheet(),
                );
              },
              child: const Text('Buka Sheet'),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  group('CreateAgendaSheet Modal Layout & Dismissal', () {
    testWidgets('respects top safe area and leaves tappable backdrop gap at top', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      tester.view.viewPadding = const FakeViewPadding(top: 48, bottom: 34);
      tester.view.padding = const FakeViewPadding(top: 48, bottom: 34);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.view.resetViewPadding();
        tester.view.resetPadding();
      });

      await tester.pumpWidget(_buildModalLauncherApp(useSafeArea: true));
      await tester.tap(find.text('Buka Sheet'));
      await tester.pumpAndSettle();

      expect(find.byType(CreateAgendaSheet), findsOneWidget);
      final sheetRect = tester.getRect(find.byType(CreateAgendaSheet));
      // 48px status bar + at least 10% safe-area backdrop gap ((800 - 48) * 0.10 = 75.2px)
      expect(sheetRect.top, greaterThanOrEqualTo(48.0 + 70.0));
      expect(tester.takeException(), isNull);

      // Tapping the visible backdrop above the sheet dismisses it.
      await tester.tapAt(Offset(180, sheetRect.top - 20));
      await tester.pumpAndSettle();

      expect(find.byType(CreateAgendaSheet), findsNothing);
    });

    testWidgets('keeps header and close button pinned while scrolled and closes on tap', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      tester.view.viewPadding = const FakeViewPadding(top: 48, bottom: 34);
      tester.view.padding = const FakeViewPadding(top: 48, bottom: 34);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.view.resetViewPadding();
        tester.view.resetPadding();
      });

      await tester.pumpWidget(_buildModalLauncherApp(useSafeArea: true));
      await tester.tap(find.text('Buka Sheet'));
      await tester.pumpAndSettle();

      final headerFinder = find.text('Buat Agenda Baru');
      final closeBtnFinder = find.byTooltip('Tutup');
      final initialHeaderTop = tester.getTopLeft(headerFinder).dy;

      // Scroll all the way to the bottom submit button.
      final saveBtn = find.text('Simpan Agenda');
      await tester.scrollUntilVisible(
        saveBtn,
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      // Header and close button stay pinned at the exact same position.
      expect(headerFinder, findsOneWidget);
      expect(closeBtnFinder, findsOneWidget);
      expect(tester.getTopLeft(headerFinder).dy, closeTo(initialHeaderTop, 0.5));

      await tester.tap(closeBtnFinder);
      await tester.pumpAndSettle();

      expect(find.byType(CreateAgendaSheet), findsNothing);
    });

    testWidgets('can be dismissed by dragging down from pinned header even after scrolling', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_buildModalLauncherApp(useSafeArea: true));
      await tester.tap(find.text('Buka Sheet'));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Simpan Agenda'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      await tester.drag(find.text('Buat Agenda Baru'), const Offset(0, 500));
      await tester.pumpAndSettle();

      expect(find.byType(CreateAgendaSheet), findsNothing);
    });

    testWidgets('renders without overflow when keyboard viewInsets are active', (tester) async {
      tester.view.physicalSize = const Size(360, 740);
      tester.view.devicePixelRatio = 1.0;
      tester.view.viewPadding = const FakeViewPadding(top: 36, bottom: 24);
      tester.view.padding = const FakeViewPadding(top: 36, bottom: 24);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.view.resetViewPadding();
        tester.view.resetPadding();
        tester.view.resetViewInsets();
      });

      await tester.pumpWidget(_buildModalLauncherApp(useSafeArea: true));
      await tester.tap(find.text('Buka Sheet'));
      await tester.pumpAndSettle();

      // Simulate open soft keyboard
      tester.view.viewInsets = const FakeViewPadding(bottom: 290);
      tester.view.padding = const FakeViewPadding(top: 36, bottom: 0);
      await tester.pumpAndSettle();

      expect(find.byTooltip('Tutup'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
