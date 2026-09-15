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

    // Verify login screen elements are present
    expect(find.text('Dekorin'), findsOneWidget);
    expect(find.text('Masuk'), findsOneWidget);
  });
}
