import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import 'package:dekorin_apps/data/datasources/remote/api_client.dart';
import 'package:dekorin_apps/data/datasources/remote/image_compressor.dart';
import 'package:dekorin_apps/data/datasources/remote/network_error_helper.dart';
import 'package:dekorin_apps/domain/models/picked_image_data.dart';
import 'package:dekorin_apps/ui/core/widgets/web_mobile_shell.dart';
import 'package:dekorin_apps/ui/features/ai_studio/widgets/before_after_slider.dart';

void main() {
  group('Cross-platform PickedImageData & ImageCompressor', () {
    test('PickedImageData.fromXFile reads bytes and normalizes extensionless filename', () async {
      final rawBytes = Uint8List.fromList([1, 2, 3, 4]);
      final xfile = XFile.fromData(rawBytes, name: 'blob_photo');

      final picked = await PickedImageData.fromXFile(xfile);
      expect(picked.bytes, rawBytes);
      expect(picked.filename.endsWith('.jpg'), true);

      final renamed = picked.copyWithBytes(Uint8List.fromList([9, 8]), newExtension: 'png');
      expect(renamed.bytes, Uint8List.fromList([9, 8]));
      expect(renamed.filename.endsWith('.png'), true);
    });

    test('ImageCompressor returns image unchanged when <= 5MB and throws on empty bytes', () async {
      final smallImage = PickedImageData(
        bytes: Uint8List.fromList(List.filled(1024, 7)),
        filename: 'small.jpg',
      );
      final result = await ImageCompressor.compressUnder5MB(smallImage);
      expect(identical(result, smallImage), true);

      final emptyImage = PickedImageData(
        bytes: Uint8List(0),
        filename: 'empty.jpg',
      );
      expect(
        () => ImageCompressor.compressUnder5MB(emptyImage),
        throwsA(isA<ApiException>()),
      );
    });

    test('isNetworkConnectionError detects http.ClientException', () {
      expect(isNetworkConnectionError(http.ClientException('network down')), true);
      expect(isNetworkConnectionError(StateError('other')), false);
    });
  });

  group('WebMobileShell & BeforeAfterSlider', () {
    testWidgets('WebMobileShell renders centered 480px frame on wide viewports and handles short heights', (tester) async {
      tester.view.physicalSize = const Size(1440, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          home: WebMobileShell(
            forceWebFrame: true,
            child: Builder(
              builder: (ctx) {
                final width = MediaQuery.sizeOf(ctx).width;
                return Scaffold(body: Center(child: Text('Width:$width')));
              },
            ),
          ),
        ),
      );
      expect(find.text('Width:480.0'), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Extreme short height (<320px) should not throw clamp error
      tester.view.physicalSize = const Size(1440, 250);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('BeforeAfterSlider accepts Uint8List beforeImageBytes without dart:io', (tester) async {
      // Valid 1x1 transparent PNG
      final png1x1 = Uint8List.fromList([
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
        0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
        0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
        0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
        0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
        0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
      ]);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BeforeAfterSlider(
              afterImageUrl: '',
              beforeImageBytes: png1x1,
            ),
          ),
        ),
      );

      expect(find.byType(Image), findsAtLeastNWidgets(1));
      expect(tester.takeException(), isNull);
    });
  });
}
