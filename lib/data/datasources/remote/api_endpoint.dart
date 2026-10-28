/// Kumpulan semua endpoint API.
///
/// Gunakan class ini agar tidak ada string URL yang tersebar
/// di banyak service (menghindari boilerplate & typo).
class ApiEndpoint {
  ApiEndpoint._(); // Tidak bisa di-instansiasi

  // ── Base URL ──────────────────────────────────────────────
  // Production VPS di Biznet GIO dengan SSL/HTTPS resmi Let's Encrypt
  static const String baseUrl = 'https://103.150.191.59.sslip.io/api';

  /// Base URL untuk Web Form (mengambil host & port dari baseUrl tanpa path /api)
  static String get webFormBaseUrl {
    final uri = Uri.parse(baseUrl);
    if (uri.hasPort && uri.port != 80 && uri.port != 443) {
      return '${uri.scheme}://${uri.host}:${uri.port}';
    }
    return '${uri.scheme}://${uri.host}';
  }

  // ── Auth ──────────────────────────────────────────────────
  static const String login = '/auth/login';
  static const String changePassword = '/auth/change-password';

  // ── Users & Company ──────────────────────────────────────
  static const String users = '/users';
  static const String companyProfile = '/company/profile';
  static const String companyBrands = '/company/brands';

  // ── Dashboard & Expenses ──────────────────────────────────
  static const String dashboardSummary = '/dashboard/summary';
  static const String expenses = '/expenses';

  // ── Agendas, Packages, Models & Addons ────────────────────
  static const String agendas = '/agendas';
  static const String packages = '/packages';
  static const String reorderPackages = '/packages/reorder';
  static const String decorationModels = '/decoration-models';
  static const String reorderDecorationModels = '/decoration-models/reorder';
  static const String addons = '/addons';
  static const String reorderAddons = '/addons/reorder';
  static const String invitations = '/invitations';

  // ── App Version / In-App Update ───────────────────────────
  static const String appVersion = '/app/version';

  /// Helper untuk membuat URL publik undangan digital
  static String getInvitationWebUrl(String slug, [String? guestName]) {
    final base = '$webFormBaseUrl/invitation/$slug';
    if (guestName != null && guestName.trim().isNotEmpty) {
      return '$base?to=${Uri.encodeComponent(guestName.trim())}';
    }
    return base;
  }
}
