# Dekorin Apps Guidelines & Rules

## 1. Asset & Icon Priority
- **Utamakan Aset Lokal**: Setiap kali membuat screen, dialog, bottom sheet, atau widget baru di `dekorin_apps`, **selalu periksa dan utamakan mengambil icon dan gambar dari folder `assets/`** (`assets/icons/`, `assets/images/`, dll.) dibandingkan menggunakan icon Material bawaan (`Icons.*`).
- **Aset Khusus yang Wajib Digunakan**:
  - **Google Maps**: Selalu gunakan `Image.asset('assets/icons/google-maps-icon.webp', width: ..., height: ...)` untuk segala hal terkait peta, lokasi, dan Maps URL (jangan gunakan `Icons.map_outlined` atau `Icons.location_on`).
  - **WhatsApp**: Gunakan `assets/icons/wa.svg` untuk tombol kontak chat WhatsApp.
- **Pengecekan Folder Assets**: Sebelum memilih icon untuk fitur baru (logo, pembayaran, media sosial, navigasi, dll.), selalu cek folder `assets/` terlebih dahulu untuk melihat apakah aset kustom sudah disediakan oleh user.
- **Pendaftaran di Pubspec**: Pastikan setiap path/sub-folder aset baru di `assets/` sudah terdaftar pada bagian `flutter: assets:` di `pubspec.yaml`.

## 2. Design System & Palette Konsisten
- Gunakan identitas visual Dekorin:
  - **Primary Gold**: `AppTheme.primaryGold` / `AppColors.primaryGold` (`#D4A574`)
  - **Secondary Gold**: `AppColors.secondaryGold` (`#C59563`)
  - **Gold Light**: `AppColors.goldLight` (`#F9F3EC`)
  - **Text Dark**: `AppColors.textDark` (`#2C2C2C`)
  - **Typography**: Gunakan `AppTypography` yang berbasis font Poppins / Plus Jakarta Sans.
