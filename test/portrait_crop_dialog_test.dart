import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dekorin_apps/config/theme/app_theme.dart';
import 'package:dekorin_apps/domain/models/picked_image_data.dart';
import 'package:dekorin_apps/ui/core/widgets/portrait_crop_dialog.dart';

class _CapturingCanvas implements Canvas {
  Rect? lastDstRect;

  @override
  void drawImageRect(ui.Image image, Rect src, Rect dst, Paint paint) {
    lastDstRect = dst;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

ui.Image _createDummyImage({int width = 200, int height = 100}) {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(
    Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    Paint()..color = const Color(0xFFFF0000),
  );
  return recorder.endRecording().toImageSync(width, height);
}

void main() {
  testWidgets('PortraitCropDialog accumulates horizontal and vertical pan smoothly across multi-step drag', (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final sourceImage = _createDummyImage();
    addTearDown(sourceImage.dispose);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: PortraitCropDialog(
            image: PickedImageData(bytes: Uint8List.fromList([1]), filename: 'wide.png'),
            aspectRatio: 3 / 4,
            debugInitialImage: sourceImage,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final canvasFinder = find.byKey(PortraitCropDialog.cropCanvasKey);
    final viewportSize = tester.getSize(canvasFinder);
    final center = tester.getCenter(canvasFinder);

    Rect readRenderedDstRect() {
      final cp = tester.widget<CustomPaint>(canvasFinder);
      final cap = _CapturingCanvas();
      cp.painter!.paint(cap, viewportSize);
      return cap.lastDstRect!;
    }

    final initialDst = readRenderedDstRect();
    expect(initialDst.center.dx, closeTo(viewportSize.width / 2, 0.01));

    // Multi-step drag right -> must accumulate well beyond a single 12px frame delta
    final gestureRight = await tester.startGesture(center);
    for (int i = 0; i < 12; i++) {
      await gestureRight.moveBy(const Offset(12, 0));
      await tester.pump();
    }
    await gestureRight.up();
    await tester.pump();

    final pannedRightDst = readRenderedDstRect();
    expect(pannedRightDst.center.dx - initialDst.center.dx, greaterThan(60.0));

    // Zoom in twice so vertical pan headroom becomes positive, then drag left and down in small steps
    await tester.tap(find.byIcon(Icons.zoom_in));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.zoom_in));
    await tester.pump();

    final zoomedDst = readRenderedDstRect();
    expect(zoomedDst.width, greaterThan(initialDst.width * 1.3));

    final gestureLeftDown = await tester.startGesture(center);
    for (int i = 0; i < 18; i++) {
      await gestureLeftDown.moveBy(const Offset(-12, 6));
      await tester.pump();
    }
    await gestureLeftDown.up();
    await tester.pump();

    final pannedLeftDownDst = readRenderedDstRect();
    expect(pannedLeftDownDst.center.dx, lessThan(viewportSize.width / 2 - 40.0));
    expect(pannedLeftDownDst.center.dy, greaterThan(viewportSize.height / 2 + 25.0));
  });
}
