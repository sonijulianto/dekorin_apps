import 'package:flutter/material.dart';
import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart';
import 'package:flutter_native_contact_picker/model/contact.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:dekorin_apps/config/theme/app_theme.dart';
import 'package:dekorin_apps/data/services/company_service.dart';
import 'package:dekorin_apps/data/services/contact_picker_service.dart';
import 'package:dekorin_apps/domain/models/agenda.dart';
import 'package:dekorin_apps/domain/models/company_profile.dart';
import 'package:dekorin_apps/domain/models/user.dart';
import 'package:dekorin_apps/ui/features/agenda/views/agenda_edit_view.dart';
import 'package:dekorin_apps/ui/features/agenda/views/create_agenda_sheet.dart';
import 'package:dekorin_apps/ui/features/login/view_models/global_auth_provider.dart';

class _FakeNativeContactPicker extends FlutterNativeContactPicker {
  _FakeNativeContactPicker({this.result});

  final Contact? result;

  @override
  Future<Contact?> selectPhoneNumber() async => result;
}

class _FakeContactPickerService extends ContactPickerService {
  _FakeContactPickerService({this.picked, this.error});

  final PickedPhoneContact? picked;
  final Object? error;
  int callCount = 0;

  @override
  Future<PickedPhoneContact?> pickPhoneContact() async {
    callCount++;
    if (error != null) throw error!;
    return picked;
  }
}

class _FakeAuthNotifier extends AuthNotifier {
  @override
  Future<User?> build() async {
    return const User(
      id: 'u1',
      name: 'Admin Test',
      role: 'owner',
      companyName: 'Dekorin Studio',
    );
  }
}

class _FakeCompanyService extends CompanyService {
  @override
  Future<List<CompanyBrand>> getCompanyBrands() async => const [];
}

Widget _buildCreateAgendaHarness(_FakeContactPickerService contactService) {
  return ProviderScope(
    overrides: [
      contactPickerServiceProvider.overrideWithValue(contactService),
      globalAuthProvider.overrideWith(() => _FakeAuthNotifier()),
      companyServiceProvider.overrideWithValue(_FakeCompanyService()),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      home: const Scaffold(
        body: SingleChildScrollView(
          child: CreateAgendaSheet(),
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID');
  });

  group('ContactPickerService Unit Tests', () {
    test('normalizePhoneNumber normalizes Indonesian and formatted numbers cleanly', () {
      expect(ContactPickerService.normalizePhoneNumber('+62 812-3456-7890'), '081234567890');
      expect(ContactPickerService.normalizePhoneNumber('+62 0812 3456 7890'), '081234567890');
      expect(ContactPickerService.normalizePhoneNumber('6281234567890'), '081234567890');
      expect(ContactPickerService.normalizePhoneNumber('0812-3456-7890'), '081234567890');
      expect(ContactPickerService.normalizePhoneNumber('(021) 555-1234'), '0215551234');
      expect(ContactPickerService.normalizePhoneNumber('\u200E+62 812\u00A03456\u20117890'), '081234567890');
      expect(ContactPickerService.normalizePhoneNumber('+65 9123 4567'), '+6591234567');
      expect(ContactPickerService.normalizePhoneNumber('+62'), '');
      expect(ContactPickerService.normalizePhoneNumber('---'), '');
    });

    test('pickPhoneContact reads selectedPhoneNumber and falls back to phoneNumbers.first', () async {
      final serviceWithSelected = ContactPickerService(
        picker: _FakeNativeContactPicker(
          result: Contact(
            fullName: '  Ibu Rina  ',
            selectedPhoneNumber: '+62 812-1111-2222',
            phoneNumbers: const ['081100000000'],
          ),
        ),
      );
      final picked = await serviceWithSelected.pickPhoneContact();
      expect(picked?.name, 'Ibu Rina');
      expect(picked?.phoneNumber, '081211112222');

      final serviceWithFallback = ContactPickerService(
        picker: _FakeNativeContactPicker(
          result: Contact(
            fullName: 'Pak Budi',
            selectedPhoneNumber: null,
            phoneNumbers: const ['6281399998888'],
          ),
        ),
      );
      final fallbackPicked = await serviceWithFallback.pickPhoneContact();
      expect(fallbackPicked?.name, 'Pak Budi');
      expect(fallbackPicked?.phoneNumber, '081399998888');

      final cancelledService = ContactPickerService(
        picker: _FakeNativeContactPicker(result: null),
      );
      expect(await cancelledService.pickPhoneContact(), isNull);
    });
  });

  group('CreateAgendaSheet Contact Picker Widget Tests', () {
    testWidgets('fills phone and empty client name when tapping Ambil dari Kontak', (tester) async {
      tester.view.physicalSize = const Size(500, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakeContactService = _FakeContactPickerService(
        picked: const PickedPhoneContact(
          name: 'Ibu Rina',
          phoneNumber: '081234567890',
        ),
      );

      await tester.pumpWidget(_buildCreateAgendaHarness(fakeContactService));
      await tester.pumpAndSettle();

      expect(find.text('Ambil dari Kontak'), findsOneWidget);

      await tester.tap(find.text('Ambil dari Kontak'));
      await tester.pumpAndSettle();

      expect(fakeContactService.callCount, 1);
      expect(find.text('081234567890'), findsOneWidget);
      expect(find.text('Ibu Rina'), findsOneWidget);
      expect(find.text('Nama & Nomor HP dari kontak "Ibu Rina" berhasil diisi!'), findsOneWidget);
    });

    testWidgets('updates only phone number when client name is already filled via suffix icon', (tester) async {
      tester.view.physicalSize = const Size(500, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakeContactService = _FakeContactPickerService(
        picked: const PickedPhoneContact(
          name: 'Kontak Lain',
          phoneNumber: '081298765432',
        ),
      );

      await tester.pumpWidget(_buildCreateAgendaHarness(fakeContactService));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Contoh: Rian & Nisa / Ibu Rina'),
        'Rian & Nisa',
      );
      await tester.pump();

      await tester.tap(find.byTooltip('Ambil dari Kontak'));
      await tester.pumpAndSettle();

      expect(find.text('Rian & Nisa'), findsOneWidget);
      expect(find.text('Kontak Lain'), findsNothing);
      expect(find.text('081298765432'), findsOneWidget);
      expect(find.text('Nomor HP dari kontak "Kontak Lain" berhasil diisi!'), findsOneWidget);
    });

    testWidgets('handles cancelled picker, empty contact number, and errors gracefully', (tester) async {
      tester.view.physicalSize = const Size(500, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      // 1. Cancelled (returns null)
      final cancelService = _FakeContactPickerService(picked: null);
      await tester.pumpWidget(_buildCreateAgendaHarness(cancelService));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ambil dari Kontak'));
      await tester.pumpAndSettle();
      expect(find.byType(SnackBar), findsNothing);

      // 2. Contact without phone number
      final emptyPhoneService = _FakeContactPickerService(
        picked: const PickedPhoneContact(name: 'Tanpa Nomor', phoneNumber: ''),
      );
      await tester.pumpWidget(_buildCreateAgendaHarness(emptyPhoneService));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ambil dari Kontak'));
      await tester.pumpAndSettle();
      expect(find.text('Kontak yang dipilih tidak memiliki nomor HP.'), findsOneWidget);

      // 3. Exception from platform channel
      final errorService = _FakeContactPickerService(error: Exception('permission error'));
      await tester.pumpWidget(_buildCreateAgendaHarness(errorService));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ambil dari Kontak'));
      await tester.pumpAndSettle();
      expect(find.text('Gagal membuka kontak perangkat. Silakan ketik nomor HP secara manual.'), findsOneWidget);
    });

    testWidgets('CreateAgendaSheet renders cleanly without overflow on narrow phone width', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakeContactService = _FakeContactPickerService();
      await tester.pumpWidget(_buildCreateAgendaHarness(fakeContactService));
      await tester.pumpAndSettle();

      expect(find.text('Ambil dari Kontak'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('AgendaEditView Contact Picker Widget Tests', () {
    testWidgets('updates phone number from contact while preserving existing client name', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final fakeContactService = _FakeContactPickerService(
        picked: const PickedPhoneContact(
          name: 'Kontak Baru',
          phoneNumber: '081355566677',
        ),
      );

      final item = AgendaItem(
        id: 'agd_1',
        clientName: 'Rian & Nisa',
        clientPhone: '081111111111',
        backdropTitle: 'Engagement',
        eventDateTime: DateTime(2026, 12, 10, 10, 0),
        mapsUrl: '',
        packageId: '',
        packageName: '',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            contactPickerServiceProvider.overrideWithValue(fakeContactService),
            globalAuthProvider.overrideWith(() => _FakeAuthNotifier()),
            companyServiceProvider.overrideWithValue(_FakeCompanyService()),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: AgendaEditView(item: item),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ambil dari Kontak'), findsOneWidget);
      await tester.tap(find.text('Ambil dari Kontak'));
      await tester.pumpAndSettle();

      expect(find.text('Rian & Nisa'), findsOneWidget);
      expect(find.text('081355566677'), findsOneWidget);
      expect(find.text('081111111111'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
