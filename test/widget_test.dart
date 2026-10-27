import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dekorin_apps/app.dart';

void main() {
  testWidgets('Login screen renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: DekorinApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify login screen elements are present (logo image, fields, button)
    expect(find.byType(Image), findsOneWidget);
    expect(find.text('Masuk ke Aplikasi'), findsOneWidget);
    expect(find.text('Nomor WhatsApp / HP'), findsOneWidget);
  });
}
