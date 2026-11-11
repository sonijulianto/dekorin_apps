import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dekorin_apps/data/datasources/remote/api_client.dart';
import 'package:dekorin_apps/data/datasources/remote/api_endpoint.dart';
import 'package:dekorin_apps/domain/models/invitation.dart';
import 'package:dekorin_apps/domain/models/wedding_plan.dart';

final coupleServiceProvider = Provider<CoupleService>((ref) {
  return CoupleService();
});

/// Service terpusat untuk fitur Calon Pengantin (Wedding Plan, Vendor & Budget, Checklist, Undangan, dan Direktori Vendor).
class CoupleService {
  // ── Wedding Plan ────────────────────────────────────────────────────────

  Future<WeddingPlanDetail> getMyPlan() async {
    final res = await ApiClient.get(ApiEndpoint.couplePlan);
    final data = res['data'] as Map<String, dynamic>? ?? const {};
    return WeddingPlanDetail.fromJson(data);
  }

  Future<WeddingPlan> updateMyPlan({
    required String title,
    required String groomName,
    required String brideName,
    required String weddingDate,
    required String akadTime,
    required String resepsiTime,
    required String city,
    required String venueName,
    required String venueAddress,
    required String mapsUrl,
    required double budgetTarget,
    required String notes,
  }) async {
    final res = await ApiClient.put(
      ApiEndpoint.couplePlan,
      body: {
        'title': title,
        'groom_name': groomName,
        'bride_name': brideName,
        'wedding_date': weddingDate,
        'akad_time': akadTime,
        'resepsi_time': resepsiTime,
        'city': city,
        'venue_name': venueName,
        'venue_address': venueAddress,
        'maps_url': mapsUrl,
        'budget_target': budgetTarget,
        'notes': notes,
      },
    );
    return WeddingPlan.fromJson(res['data'] as Map<String, dynamic>? ?? const {});
  }

  Future<WeddingPlan> joinPlanByCode(String joinCode) async {
    final res = await ApiClient.post(
      ApiEndpoint.couplePlanJoin,
      body: {'join_code': joinCode.trim().toUpperCase()},
    );
    return WeddingPlan.fromJson(res['data'] as Map<String, dynamic>? ?? const {});
  }

  // ── Vendors & Budget ────────────────────────────────────────────────────

  Future<List<WeddingPlanVendorItem>> getVendors() async {
    final res = await ApiClient.get(ApiEndpoint.coupleVendors);
    final list = res['data'] as List<dynamic>? ?? const [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(WeddingPlanVendorItem.fromJson)
        .toList();
  }

  Future<WeddingPlanVendorItem> addManualVendor({
    required String category,
    required String name,
    String phone = '',
    String instagram = '',
    String packageName = '',
    double agreedPrice = 0,
    double dpPaid = 0,
    String paymentStatus = '',
    String dueDate = '',
    String notes = '',
  }) async {
    final res = await ApiClient.post(
      ApiEndpoint.coupleVendors,
      body: {
        'vendor_category': category,
        'vendor_name': name,
        'vendor_phone': phone,
        'vendor_instagram': instagram,
        'package_name': packageName,
        'agreed_price': agreedPrice,
        'dp_paid': dpPaid,
        if (paymentStatus.isNotEmpty) 'payment_status': paymentStatus,
        'due_date': dueDate,
        'notes': notes,
      },
    );
    return WeddingPlanVendorItem.fromJson(res['data'] as Map<String, dynamic>? ?? const {});
  }

  Future<WeddingPlanVendorItem> updateVendor(
    String id, {
    required String category,
    required String name,
    String phone = '',
    String instagram = '',
    String packageName = '',
    double agreedPrice = 0,
    double dpPaid = 0,
    String paymentStatus = '',
    String dueDate = '',
    String notes = '',
  }) async {
    final res = await ApiClient.put(
      '${ApiEndpoint.coupleVendors}/$id',
      body: {
        'vendor_category': category,
        'vendor_name': name,
        'vendor_phone': phone,
        'vendor_instagram': instagram,
        'package_name': packageName,
        'agreed_price': agreedPrice,
        'dp_paid': dpPaid,
        if (paymentStatus.isNotEmpty) 'payment_status': paymentStatus,
        'due_date': dueDate,
        'notes': notes,
      },
    );
    return WeddingPlanVendorItem.fromJson(res['data'] as Map<String, dynamic>? ?? const {});
  }

  Future<void> deleteVendor(String id) async {
    await ApiClient.delete('${ApiEndpoint.coupleVendors}/$id');
  }

  Future<WeddingPlanVendorItem> linkDekorinAgenda(String tokenOrUrl) async {
    final res = await ApiClient.post(
      ApiEndpoint.coupleLinkAgenda,
      body: {'token_or_url': tokenOrUrl.trim()},
    );
    return WeddingPlanVendorItem.fromJson(res['data'] as Map<String, dynamic>? ?? const {});
  }

  Future<WeddingPlanVendorItem> addPublicVendorToPlan({
    required String companyId,
    String packageName = '',
    double agreedPrice = 0,
    String notes = '',
  }) async {
    final res = await ApiClient.post(
      ApiEndpoint.coupleAddPublicVendor,
      body: {
        'company_id': companyId,
        'package_name': packageName,
        'agreed_price': agreedPrice,
        'notes': notes,
      },
    );
    return WeddingPlanVendorItem.fromJson(res['data'] as Map<String, dynamic>? ?? const {});
  }

  // ── Checklist Tugas ─────────────────────────────────────────────────────

  Future<List<WeddingTaskItem>> getTasks() async {
    final res = await ApiClient.get(ApiEndpoint.coupleTasks);
    final list = res['data'] as List<dynamic>? ?? const [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(WeddingTaskItem.fromJson)
        .toList();
  }

  Future<WeddingTaskItem> createTask({
    required String title,
    required String category,
    required String phase,
    String dueDate = '',
    String notes = '',
  }) async {
    final res = await ApiClient.post(
      ApiEndpoint.coupleTasks,
      body: {
        'title': title,
        'category': category,
        'phase': phase,
        'due_date': dueDate,
        'notes': notes,
      },
    );
    return WeddingTaskItem.fromJson(res['data'] as Map<String, dynamic>? ?? const {});
  }

  Future<WeddingTaskItem> toggleTask(String id) async {
    final res = await ApiClient.patch('${ApiEndpoint.coupleTasks}/$id/toggle');
    return WeddingTaskItem.fromJson(res['data'] as Map<String, dynamic>? ?? const {});
  }

  Future<void> deleteTask(String id) async {
    await ApiClient.delete('${ApiEndpoint.coupleTasks}/$id');
  }

  // ── Klaim & Kelola Undangan Digital ─────────────────────────────────────

  Future<List<InvitationItem>> getClaimedInvitations() async {
    final res = await ApiClient.get(ApiEndpoint.coupleInvitations);
    final list = res['data'] as List<dynamic>? ?? const [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(InvitationItem.fromJson)
        .toList();
  }

  Future<InvitationItem> claimInvitation({
    String slug = '',
    String pin = '',
    String editTokenOrUrl = '',
  }) async {
    final res = await ApiClient.post(
      ApiEndpoint.coupleClaimInvitation,
      body: {
        if (slug.trim().isNotEmpty) 'slug': slug.trim(),
        if (pin.trim().isNotEmpty) 'pin': pin.trim(),
        if (editTokenOrUrl.trim().isNotEmpty) 'edit_token_or_url': editTokenOrUrl.trim(),
      },
    );
    return InvitationItem.fromJson(res['data'] as Map<String, dynamic>? ?? const {});
  }

  Future<void> unclaimInvitation(String id) async {
    await ApiClient.delete('${ApiEndpoint.coupleInvitations}/$id/claim');
  }

  Future<InvitationItem> getClaimedInvitationDetail(String id) async {
    final res = await ApiClient.get('${ApiEndpoint.coupleInvitations}/$id');
    return InvitationItem.fromJson(res['data'] as Map<String, dynamic>? ?? const {});
  }

  Future<InvitationItem> updateClaimedInvitation(String id, Map<String, dynamic> payload) async {
    final res = await ApiClient.put('${ApiEndpoint.coupleInvitations}/$id', body: payload);
    return InvitationItem.fromJson(res['data'] as Map<String, dynamic>? ?? const {});
  }

  Future<InvitationItem> saveClaimedInvitationGuests(String id, String guestListJson) async {
    final res = await ApiClient.put(
      '${ApiEndpoint.coupleInvitations}/$id/guests',
      body: {'guest_list_json': guestListJson},
    );
    return InvitationItem.fromJson(res['data'] as Map<String, dynamic>? ?? const {});
  }

  Future<InvitationItem> syncPlanToInvitation(String id) async {
    final res = await ApiClient.post('${ApiEndpoint.coupleInvitations}/$id/sync-plan');
    return InvitationItem.fromJson(res['data'] as Map<String, dynamic>? ?? const {});
  }

  // ── Direktori Vendor Publik ─────────────────────────────────────────────

  Future<List<PublicVendorSummary>> getPublicVendors({
    String category = 'all',
    String city = '',
    String search = '',
    int page = 1,
    int limit = 30,
  }) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (category.trim().isNotEmpty && category != 'all') {
      queryParams['category'] = category.trim();
    }
    if (city.trim().isNotEmpty) {
      queryParams['city'] = city.trim();
    }
    if (search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }

    final qs = Uri(queryParameters: queryParams).query;
    final res = await ApiClient.get('${ApiEndpoint.vendorDirectory}?$qs');
    final list = res['data'] as List<dynamic>? ?? const [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(PublicVendorSummary.fromJson)
        .toList();
  }

  Future<PublicVendorDetail> getPublicVendorDetail(String id) async {
    final res = await ApiClient.get('${ApiEndpoint.vendorDirectory}/$id');
    return PublicVendorDetail.fromJson(res['data'] as Map<String, dynamic>? ?? const {});
  }
}
