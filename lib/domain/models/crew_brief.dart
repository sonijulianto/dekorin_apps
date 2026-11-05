import 'dart:io';
import 'dart:typed_data';

/// Model data untuk satu seksi lembar kerja visual crew dekorasi.
/// Berisi satu foto (bisa dari file lokal, URL, atau bytes) dan daftar catatan instruksi.
class CrewBriefSection {
  CrewBriefSection({
    this.title = '',
    this.imageFile,
    this.imageUrl,
    this.imageBytes,
    List<String>? notes,
  }) : notes = notes ?? [''];

  String title;
  File? imageFile;
  String? imageUrl;
  Uint8List? imageBytes;
  List<String> notes;

  bool get hasImage =>
      imageFile != null ||
      (imageUrl != null && imageUrl!.trim().isNotEmpty) ||
      (imageBytes != null && imageBytes!.isNotEmpty);
}
