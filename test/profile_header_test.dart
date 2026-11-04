import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dekorin_apps/config/theme/app_theme.dart';
import 'package:dekorin_apps/domain/models/user.dart';
import 'package:dekorin_apps/ui/features/login/view_models/global_auth_provider.dart';
import 'package:dekorin_apps/ui/features/profile/views/profile_view.dart';

class _FakeAuthNotifier extends AuthNotifier {
  @override
  Future<User?> build() async {
    return const User(
      id: 'u1',
      name: 'Soni Julianto',
      phone: '089516789565',
      email: 'soni@dekorin.com',
      role: 'superadmin',
      companyName: 'Family Backdrop',
      companyAddress: 'Jl. Mayor Oking Jaya Atmaja Gg. H. Ikhsan RT 03/RW 01',
    );
  }
}

void main() {
  testWidgets('ProfileView renders VIP Gold Header card with matching design and info', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          globalAuthProvider.overrideWith(() => _FakeAuthNotifier()),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ProfileView(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify Company Name & Address
    expect(find.text('Family Backdrop'), findsOneWidget);
    expect(find.text('Jl. Mayor Oking Jaya Atmaja Gg. H. Ikhsan RT 03/RW 01'), findsOneWidget);

    // Verify User Name & Phone
    expect(find.text('Soni Julianto'), findsOneWidget);
    expect(find.text('089516789565'), findsOneWidget);

    // Verify Role Badge
    expect(find.text('Superadmin'), findsOneWidget);

    // Verify Location Icon
    expect(find.byIcon(Icons.location_on), findsOneWidget);
  });

  testWidgets('ProfileView header handles narrow 320px screen without overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          globalAuthProvider.overrideWith(() => _FakeAuthNotifier()),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const ProfileView(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Family Backdrop'), findsOneWidget);
  });
}
