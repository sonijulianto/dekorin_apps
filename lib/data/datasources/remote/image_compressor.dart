import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';

import 'package:dekorin_apps/data/datasources/remote/api_client.dart';

/// Helper untuk melakukan kompresi bertingkat (Auto Multi-Pass Compression)
/// guna memastikan ukuran file selalu berada di bawah batas maksimal (5 MB)
/// sebelum dikirim ke server backend.
class ImageCompressor {
  ImageCompressor._();

  /// Batas maksimal file yang diizinkan oleh server (5 MB)
  static const int maxFileBytes = 5 * 1024 * 1024; // 5 MB

  /// Melakukan validasi dan kompresi bertingkat (Auto Multi-Pass) secara otomatis.
  ///
  /// - Jika file sudah <= 5 MB, langsung dikembalikan tanpa proses tambahan (hemat baterai & CPU).
  /// - Jika file > 5 MB:
  ///   * Pass 1: Resize maksimal 1920px & Quality 80 (JPEG)
  ///   * Pass 2: Resize maksimal 1440px & Quality 70 (JPEG)
  ///   * Pass 3: Resize maksimal 1080px & Quality 60 (JPEG)
  /// - Jika setelah Pass 3 masih melebihi 5 MB, melempar [ApiException] dengan pesan yang jelas.
  static Future<File> compressUnder5MB(File file) async {
    if (!await file.exists()) {
      throw ApiException('File gambar tidak ditemukan di perangkat.');
    }

    final initialBytes = await file.length();
    // Jika ukuran sudah aman <= 5MB, tidak perlu kompresi ulang
    if (initialBytes <= maxFileBytes) {
      return file;
    }

    // Strategi kompresi multi-pass bertahap
    final passes = [
      _CompressionConfig(minWidth: 1920, minHeight: 1920, quality: 80),
      _CompressionConfig(minWidth: 1440, minHeight: 1440, quality: 70),
      _CompressionConfig(minWidth: 1080, minHeight: 1080, quality: 60),
    ];

    File currentFile = file;
    final tempDir = Directory.systemTemp;

    for (int i = 0; i < passes.length; i++) {
      final config = passes[i];
      final targetPath = '${tempDir.path}/compress_${DateTime.now().millisecondsSinceEpoch}_p${i + 1}.jpg';

      try {
        final XFile? compressedXFile = await FlutterImageCompress.compressAndGetFile(
          currentFile.absolute.path,
          targetPath,
          quality: config.quality,
          minWidth: config.minWidth,
          minHeight: config.minHeight,
          format: CompressFormat.jpeg,
        );

        if (compressedXFile != null) {
          final candidate = File(compressedXFile.path);
          final candidateSize = await candidate.length();

          // Berhasil memenuhi batas <= 5 MB
          if (candidateSize <= maxFileBytes) {
            return candidate;
          }

          currentFile = candidate;
        }
      } catch (_) {
        // Jika gagal di salah satu pass, lanjutkan ke pass berikutnya
      }
    }

    // Pengecekan akhir setelah seluruh pass dijalankan
    final finalBytes = await currentFile.length();
    if (finalBytes > maxFileBytes) {
      final sizeMb = (finalBytes / (1024 * 1024)).toStringAsFixed(1);
      throw ApiException(
        'Ukuran gambar masih terlalu besar ($sizeMb MB) setelah kompresi otomatis. '
        'Maksimal ukuran yang diizinkan adalah 5 MB. Harap pilih gambar lain.',
      );
    }

    return currentFile;
  }
}

class _CompressionConfig {
  final int minWidth;
  final int minHeight;
  final int quality;

  _CompressionConfig({
    required this.minWidth,
    required this.minHeight,
    required this.quality,
  });
}
