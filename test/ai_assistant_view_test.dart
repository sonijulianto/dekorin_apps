import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dekorin_apps/config/theme/app_theme.dart';
import 'package:dekorin_apps/ui/features/dashboard/views/ai_assistant_view.dart';

void main() {
  testWidgets('AIAssistantView input bar renders unified pill decoration without nested border box',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(375, 812));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const AIAssistantView(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final textFieldFinder = find.byType(TextField);
    expect(textFieldFinder, findsOneWidget);

    final textField = tester.widget<TextField>(textFieldFinder);
    final decoration = textField.decoration!;
    expect(decoration.hintText, 'Tanyakan sesuatu seputar bisnis Anda...');
    expect(decoration.filled, isTrue);
    expect(decoration.fillColor, const Color(0xFFF7F4EF));

    // Pastikan seluruh state border di-override menjadi pill radius 24
    // agar tidak mewarisi OutlineInputBorder radius 12 / putih dari AppTheme.
    final enabledBorder = decoration.enabledBorder as OutlineInputBorder;
    final focusedBorder = decoration.focusedBorder as OutlineInputBorder;
    expect(enabledBorder.borderRadius, BorderRadius.circular(24));
    expect(focusedBorder.borderRadius, BorderRadius.circular(24));
    expect(focusedBorder.borderSide.color, AppColors.primaryGold);

    // Pastikan tinggi input pill seimbang dengan tombol kirim (44px).
    final inputSize = tester.getSize(textFieldFinder);
    final sendIconFinder = find.byIcon(Icons.send_rounded);
    expect(sendIconFinder, findsOneWidget);
    expect(inputSize.height, greaterThanOrEqualTo(44.0));

    // Simulasikan tap & ketik untuk memastikan state fokus dan multiline tetap rapi tanpa error.
    await tester.tap(textFieldFinder);
    await tester.enterText(textFieldFinder, 'Berapa omset bulan ini?');
    await tester.pump();
    expect(find.text('Berapa omset bulan ini?'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
