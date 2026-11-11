import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';

import 'package:dekorin_apps/data/datasources/remote/api_client.dart';
import 'package:dekorin_apps/domain/models/picked_image_data.dart';

/// Helper untuk melakukan kompresi bertingkat (Auto Multi-Pass Compression)
/// guna memastikan ukuran file selalu berada di bawah batas maksimal (5 MB)
/// sebelum dikirim ke server backend. Berjalan lintas-platform (Mobile & Web).
class ImageCompressor {
  ImageCompressor._();

  /// Batas maksimal file yang diizinkan oleh server (5 MB)
  static const int maxFileBytes = 5 * 1024 * 1024; // 5 MB

  /// Melakukan validasi dan kompresi bertingkat (Auto Multi-Pass) secara otomatis.
  ///
  /// - Jika gambar sudah <= 5 MB, langsung dikembalikan tanpa proses tambahan.
  /// - Jika gambar > 5 MB:
  ///   * Pass 1: Resize maksimal 1920px & Quality 80 (JPEG)
  ///   * Pass 2: Resize maksimal 1440px & Quality 70 (JPEG)
  ///   * Pass 3: Resize maksimal 1080px & Quality 60 (JPEG)
  /// - Jika setelah Pass 3 masih melebihi 5 MB, melempar [ApiException] dengan pesan yang jelas.
  static Future<PickedImageData> compressUnder5MB(PickedImageData image) async {
    if (image.bytes.isEmpty) {
      throw ApiException('Data gambar kosong atau gagal dibaca.');
    }

    // Jika ukuran sudah aman <= 5MB, tidak perlu kompresi ulang
    if (image.bytes.lengthInBytes <= maxFileBytes) {
      return image;
    }

    // Strategi kompresi multi-pass bertahap
    const passes = [
      _CompressionConfig(minWidth: 1920, minHeight: 1920, quality: 80),
      _CompressionConfig(minWidth: 1440, minHeight: 1440, quality: 70),
      _CompressionConfig(minWidth: 1080, minHeight: 1080, quality: 60),
    ];

    Uint8List currentBytes = image.bytes;

    for (final config in passes) {
      try {
        final compressedBytes = await FlutterImageCompress.compressWithList(
          currentBytes,
          quality: config.quality,
          minWidth: config.minWidth,
          minHeight: config.minHeight,
          format: CompressFormat.jpeg,
        );

        if (compressedBytes.isNotEmpty) {
          currentBytes = compressedBytes;
          if (currentBytes.lengthInBytes <= maxFileBytes) {
            return image.copyWithBytes(currentBytes, newExtension: 'jpg');
          }
        }
      } catch (_) {
        // Jika gagal di salah satu pass, lanjutkan ke pass berikutnya
      }
    }

    if (currentBytes.lengthInBytes > maxFileBytes) {
      final sizeMb = (currentBytes.lengthInBytes / (1024 * 1024)).toStringAsFixed(1);
      throw ApiException(
        'Ukuran gambar masih terlalu besar ($sizeMb MB) setelah kompresi otomatis. '
        'Maksimal ukuran yang diizinkan adalah 5 MB. Harap pilih gambar lain.',
      );
    }

    return image.copyWithBytes(currentBytes, newExtension: 'jpg');
  }
}

class _CompressionConfig {
  const _CompressionConfig({
    required this.minWidth,
    required this.minHeight,
    required this.quality,
  });

  final int minWidth;
  final int minHeight;
  final int quality;
}
