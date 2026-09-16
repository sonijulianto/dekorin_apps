/// Kumpulan semua endpoint API.
///
/// Gunakan class ini agar tidak ada string URL yang tersebar
/// di banyak service (menghindari boilerplate & typo).
class ApiEndpoint {
  ApiEndpoint._(); // Tidak bisa di-instansiasi

  // ── Base URL ──────────────────────────────────────────────
  // Gunakan 10.0.2.2 untuk Android Emulator,
  // 127.0.0.1 untuk iOS Simulator / Web / macOS.
  // Ganti sesuai IP jika testing di device fisik.
  static const String baseUrl = 'http://192.168.1.99:3000/api';

  /// Base URL untuk Web Form (mengambil host & port dari baseUrl tanpa path /api)
  static String get webFormBaseUrl {
    final uri = Uri.parse(baseUrl);
    return '${uri.scheme}://${uri.host}:${uri.port}';
  }

  // ── Auth ──────────────────────────────────────────────────
  static const String login = '/auth/login';

  // ── Users ─────────────────────────────────────────────────
  static const String users = '/users';

  // ── Agendas & Packages ───────────────────────────────────
  static const String agendas = '/agendas';
  static const String packages = '/packages';
}
