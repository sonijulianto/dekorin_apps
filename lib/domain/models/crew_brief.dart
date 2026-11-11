import 'dart:typed_data';

/// Model data untuk satu seksi lembar kerja visual crew dekorasi.
/// Berisi satu foto (bisa dari URL atau bytes lintas-platform) dan daftar catatan instruksi.
class CrewBriefSection {
  CrewBriefSection({
    this.title = '',
    this.imageUrl,
    this.imageBytes,
    List<String>? notes,
  }) : notes = notes ?? [''];

  String title;
  String? imageUrl;
  Uint8List? imageBytes;
  List<String> notes;

  bool get hasImage =>
      (imageUrl != null && imageUrl!.trim().isNotEmpty) ||
      (imageBytes != null && imageBytes!.isNotEmpty);
}
