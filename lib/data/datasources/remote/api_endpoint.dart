import 'package:flutter/foundation.dart';

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
  static const String registerCouple = '/auth/register-couple';
  static const String changePassword = '/auth/change-password';

  // ── Couple / Calon Pengantin & Direktori Vendor ───────────
  static const String couplePlan = '/couple/plan';
  static const String couplePlanJoin = '/couple/plan/join';
  static const String coupleVendors = '/couple/vendors';
  static const String coupleLinkAgenda = '/couple/vendors/link-agenda';
  static const String coupleAddPublicVendor = '/couple/vendors/from-directory';
  static const String coupleTasks = '/couple/tasks';
  static const String coupleInvitations = '/couple/invitations';
  static const String coupleClaimInvitation = '/couple/invitations/claim';
  static const String vendorDirectory = '/vendors/directory';

  // ── Users & Company ──────────────────────────────────────
  static const String users = '/users';
  static const String companyProfile = '/company/profile';
  static const String companyBrands = '/company/brands';
  static const String invoiceTemplate = '/company/invoice-template';
  static const String rolePermissions = '/company/role-permissions';
  static const String resetRolePermissions = '/company/role-permissions/reset';
  static const String formConfig = '/company/form-config';
  static const String formConfigTemplates = '/company/form-config/templates';
  static const String resetFormConfig = '/company/form-config/reset';

  // ── Dashboard & Expenses ──────────────────────────────────
  static const String dashboardSummary = '/dashboard/summary';
  static const String expenses = '/expenses';
  static const String aiScanReceipt = '/ai/scan-receipt';
  static const String aiAssistant = '/ai/assistant';
  static const String aiSimulateDecor = '/ai/simulate-decor';

  // ── Agendas, Packages, Models & Addons ────────────────────
  static const String agendas = '/agendas';
  static const String generateAgendaLink = '/agendas/generate-link';
  static const String pendingAgendaLinks = '/agendas/pending-links';
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

  /// Helper untuk membuat URL live interactive preview desain template undangan digital
  static String getInvitationTemplatePreviewUrl(String templateId, [String? slug]) {
    final uri = Uri.parse(baseUrl);
    final isProdDomain = uri.host == 'dekorin.my.id' || uri.host.endsWith('.dekorin.my.id');
    final base = isProdDomain
        ? '$invitationDomainBaseUrl/preview/$templateId'
        : '$webFormBaseUrl/invitation/preview/$templateId';
    if (slug != null && slug.trim().isNotEmpty) {
      return '$base?slug=${Uri.encodeComponent(slug.trim())}&preview=1';
    }
    return '$base?preview=1';
  }

  /// Helper untuk membuat URL Visual Click-to-Edit Editor undangan digital (?preview=1&edit=1)
  static String getInvitationVisualEditorUrl(String slug, {String? templateOverride}) {
    final uri = Uri.parse(baseUrl);
    final isProdDomain = uri.host == 'dekorin.my.id' || uri.host.endsWith('.dekorin.my.id');
    final cleanSlug = Uri.encodeComponent(slug.trim());
    final bool isAppSubdomain = kIsWeb && Uri.base.host == 'app.dekorin.my.id';
    final base = isAppSubdomain
        ? '${Uri.base.origin}/invitation/$cleanSlug'
        : isProdDomain
            ? '$invitationDomainBaseUrl/$cleanSlug'
            : '$webFormBaseUrl/invitation/$cleanSlug';
    final queryParts = <String>['preview=1', 'edit=1'];
    if (templateOverride != null && templateOverride.trim().isNotEmpty) {
      queryParts.add('template=${Uri.encodeComponent(templateOverride.trim())}');
    }
    return '$base?${queryParts.join('&')}';
  }
}
