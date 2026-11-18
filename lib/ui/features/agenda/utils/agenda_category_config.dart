/// Konfigurasi tampilan dan perilaku form Buat/Edit/Detail Agenda
/// berdasarkan kategori usaha (company category) aktif.
class AgendaCategoryConfig {
  const AgendaCategoryConfig({
    required this.category,
    required this.isDecoration,
    required this.packageFieldLabel,
    required this.packageEditLabel,
    required this.packagePriceLabel,
    required this.packagePickerPlaceholder,
    required this.packageSectionTitle,
    required this.notesHint,
    required this.brandHelpText,
  });

  final String category;
  final bool isDecoration;

  /// Label field pilih paket di Create Agenda
  final String packageFieldLabel;

  /// Label field paket di Edit Agenda
  final String packageEditLabel;

  /// Label field harga paket di Edit Agenda
  final String packagePriceLabel;

  /// Placeholder ketika belum memilih paket di Create Agenda
  final String packagePickerPlaceholder;

  /// Judul section paket di Edit Agenda
  final String packageSectionTitle;

  /// Hint text untuk field catatan di Create & Edit Agenda
  final String notesHint;

  /// Keterangan helper pada pemilih brand
  final String brandHelpText;

  bool get showBackdropField => isDecoration;
  bool get showModelSection => isDecoration;
  bool get showAddonSection => isDecoration;
  bool get showModelConceptCard => isDecoration;
  bool get showPickListAndCrewBrief => isDecoration;

  /// Menormalisasi kode kategori vendor agar konsisten dengan backend.
  static String normalizeCategory(String raw) {
    switch (raw.trim().toLowerCase()) {
      case '':
      case 'decoration':
      case 'dekorasi':
        return 'decoration';
      case 'mua':
      case 'makeup':
      case 'rias':
        return 'mua';
      case 'photo_video':
      case 'photography':
      case 'foto':
      case 'dokumentasi':
        return 'photo_video';
      case 'mc':
      case 'master_of_ceremony':
      case 'pembawa_acara':
        return 'mc';
      case 'wo':
      case 'wedding_organizer':
        return 'wo';
      case 'catering':
      case 'katering':
        return 'catering';
      case 'attire':
      case 'busana':
        return 'attire';
      case 'entertainment':
      case 'hiburan':
      case 'music':
        return 'entertainment';
      case 'venue':
        return 'venue';
      case 'other':
      case 'lainnya':
        return 'other';
      default:
        return raw.trim().toLowerCase();
    }
  }

  factory AgendaCategoryConfig.fromCategory(String rawCategory) {
    final normalized = normalizeCategory(rawCategory);
    switch (normalized) {
      case 'decoration':
        return const AgendaCategoryConfig(
          category: 'decoration',
          isDecoration: true,
          packageFieldLabel: 'Pilih Paket Dekorasi (Opsional)',
          packageEditLabel: 'Paket Dekorasi',
          packagePriceLabel: 'Harga Paket Dekorasi',
          packagePickerPlaceholder: 'Ketuk untuk pilih paket dekorasi',
          packageSectionTitle: 'Paket & Model Dekorasi',
          notesHint: 'Misal: Tema warna sage green, loading barang H-1...',
          brandHelpText: 'Menentukan nama & logo invoice serta daftar Paket & Model yang tampil.',
        );
      case 'mua':
        return const AgendaCategoryConfig(
          category: 'mua',
          isDecoration: false,
          packageFieldLabel: 'Pilih Paket MUA / Rias (Opsional)',
          packageEditLabel: 'Paket MUA / Rias',
          packagePriceLabel: 'Harga Paket MUA',
          packagePickerPlaceholder: 'Ketuk untuk pilih paket MUA / rias',
          packageSectionTitle: 'Paket Layanan',
          notesHint: 'Contoh: Jumlah orang dirias, jam mulai makeup, atau request look khusus...',
          brandHelpText: 'Menentukan nama & logo invoice serta daftar Paket yang tampil.',
        );
      case 'photo_video':
        return const AgendaCategoryConfig(
          category: 'photo_video',
          isDecoration: false,
          packageFieldLabel: 'Pilih Paket Foto & Video (Opsional)',
          packageEditLabel: 'Paket Foto & Video',
          packagePriceLabel: 'Harga Paket Foto & Video',
          packagePickerPlaceholder: 'Ketuk untuk pilih paket foto & video',
          packageSectionTitle: 'Paket Layanan',
          notesHint: 'Contoh: Konsep foto/video, jam mulai liputan, atau request khusus lainnya...',
          brandHelpText: 'Menentukan nama & logo invoice serta daftar Paket yang tampil.',
        );
      case 'mc':
        return const AgendaCategoryConfig(
          category: 'mc',
          isDecoration: false,
          packageFieldLabel: 'Pilih Paket MC (Opsional)',
          packageEditLabel: 'Paket MC',
          packagePriceLabel: 'Harga Paket MC',
          packagePickerPlaceholder: 'Ketuk untuk pilih paket MC',
          packageSectionTitle: 'Paket Layanan',
          notesHint: 'Contoh: Konsep acara, susunan acara singkat, atau request khusus lainnya...',
          brandHelpText: 'Menentukan nama & logo invoice serta daftar Paket yang tampil.',
        );
      default:
        return AgendaCategoryConfig(
          category: normalized,
          isDecoration: false,
          packageFieldLabel: 'Pilih Paket Layanan (Opsional)',
          packageEditLabel: 'Paket Layanan',
          packagePriceLabel: 'Harga Paket',
          packagePickerPlaceholder: 'Ketuk untuk pilih paket layanan',
          packageSectionTitle: 'Paket Layanan',
          notesHint: 'Contoh: Detail kebutuhan acara, jam mulai, atau request khusus lainnya...',
          brandHelpText: 'Menentukan nama & logo invoice serta daftar Paket yang tampil.',
        );
    }
  }
}
