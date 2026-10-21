/// Kumpulan semua endpoint API.
///
/// Gunakan class ini agar tidak ada string URL yang tersebar
/// di banyak service (menghindari boilerplate & typo).
class ApiEndpoint {
  ApiEndpoint._(); // Tidak bisa di-instansiasi

  // ── Base URL ──────────────────────────────────────────────
  // Menggunakan ngrok static domain → tidak perlu ubah IP lagi!
  // Pastikan ngrok sudah berjalan: ngrok http --domain=ashen-mongrel-renounce.ngrok-free.dev 3000
  static const String baseUrl = 'https://ashen-mongrel-renounce.ngrok-free.dev/api';

  /// Base URL untuk Web Form (mengambil host & port dari baseUrl tanpa path /api)
  static String get webFormBaseUrl {
    final uri = Uri.parse(baseUrl);
    return '${uri.scheme}://${uri.host}:${uri.port}';
  }

  // ── Auth ──────────────────────────────────────────────────
  static const String login = '/auth/login';

  // ── Users ─────────────────────────────────────────────────
  static const String users = '/users';

  // ── Dashboard & Expenses ──────────────────────────────────
  static const String dashboardSummary = '/dashboard/summary';
  static const String expenses = '/expenses';

  // ── Agendas, Packages & Addons ──────────────────────────────
  static const String agendas = '/agendas';
  static const String packages = '/packages';
  static const String reorderPackages = '/packages/reorder';
  static const String addons = '/addons';
  static const String reorderAddons = '/addons/reorder';
  static const String invitations = '/invitations';

  /// Helper untuk membuat URL publik undangan digital
  static String getInvitationWebUrl(String slug, [String? guestName]) {
    final base = '$webFormBaseUrl/invitation/$slug';
    if (guestName != null && guestName.trim().isNotEmpty) {
      return '$base?to=${Uri.encodeComponent(guestName.trim())}';
    }
    return base;
  }
}
