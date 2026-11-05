/// Kumpulan semua endpoint API.
///
/// Gunakan class ini agar tidak ada string URL yang tersebar
/// di banyak service (menghindari boilerplate & typo).
class ApiEndpoint {
  ApiEndpoint._(); // Tidak bisa di-instansiasi

  // ── Base URL ──────────────────────────────────────────────
  // Production VPS di Biznet GIO dengan proteksi Cloudflare & SSL resmi
  static const String baseUrl = 'https://dekorin.my.id/api';

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
  static const String aiScanReceipt = '/ai/scan-receipt';
  static const String aiAssistant = '/ai/assistant';
  static const String aiSimulateDecor = '/ai/simulate-decor';

  // ── Agendas, Packages, Models & Addons ────────────────────
  static const String agendas = '/agendas';
  static const String packages = '/packages';
  static const String reorderPackages = '/packages/reorder';
  static const String decorationModels = '/decoration-models';
  static const String reorderDecorationModels = '/decoration-models/reorder';
  static const String addons = '/addons';
  static const String reorderAddons = '/addons/reorder';
  static const String properties = '/properties';
  static const String propertiesAvailability = '/properties/availability';
  static const String invitations = '/invitations';

  // ── App Version / In-App Update ───────────────────────────
  static const String appVersion = '/app/version';

  /// Base URL khusus Subdomain Undangan Digital & Portal Pengantin
  static String get invitationDomainBaseUrl {
    final uri = Uri.parse(baseUrl);
    if (uri.host == 'dekorin.my.id' || uri.host.endsWith('.dekorin.my.id')) {
      return 'https://undangan.dekorin.my.id';
    }
    return webFormBaseUrl;
  }

  /// Helper untuk membuat URL publik undangan digital (https://undangan.dekorin.my.id/:slug)
  static String getInvitationWebUrl(String slug, [String? guestName]) {
    final uri = Uri.parse(baseUrl);
    final isProdDomain = uri.host == 'dekorin.my.id' || uri.host.endsWith('.dekorin.my.id');
    final base = isProdDomain ? '$invitationDomainBaseUrl/$slug' : '$webFormBaseUrl/invitation/$slug';
    if (guestName != null && guestName.trim().isNotEmpty) {
      return '$base?to=${Uri.encodeComponent(guestName.trim())}';
    }
    return base;
  }

  /// Helper untuk membuat URL Portal Kelola Mandiri Pengantin (1-Klik Token)
  static String getInvitationPortalManageUrl(String editToken) {
    return '$invitationDomainBaseUrl/kelola/$editToken';
  }
}
