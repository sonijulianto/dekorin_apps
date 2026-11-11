import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

/// Representasi gambar lintas-platform (Mobile & Web) berbasis bytes
/// agar logika preview, crop, kompresi, dan upload tidak bergantung pada `dart:io`.
class PickedImageData {
  const PickedImageData({
    required this.bytes,
    this.filename = 'image.jpg',
  });

  final Uint8List bytes;
  final String filename;

  int get lengthInBytes => bytes.length;

  /// Membaca [XFile] dari `image_picker` menjadi [PickedImageData].
  static Future<PickedImageData> fromXFile(XFile file) async {
    final bytes = await file.readAsBytes();
    final rawName = file.name.trim();
    final safeName = rawName.isNotEmpty && rawName.contains('.')
        ? rawName
        : 'image_${DateTime.now().millisecondsSinceEpoch}.jpg';
    return PickedImageData(
      bytes: bytes,
      filename: safeName,
    );
  }

  /// Mengembalikan salinan dengan ekstensi nama file diganti ke [extension] (tanpa titik).
  PickedImageData copyWithBytes(Uint8List newBytes, {String? newExtension}) {
    if (newExtension == null || newExtension.isEmpty) {
      return PickedImageData(bytes: newBytes, filename: filename);
    }
    final dotIndex = filename.lastIndexOf('.');
    final baseName = dotIndex > 0 ? filename.substring(0, dotIndex) : filename;
    return PickedImageData(
      bytes: newBytes,
      filename: '$baseName.$newExtension',
    );
  }
}
