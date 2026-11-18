import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:dekorin_apps/data/datasources/remote/api_client.dart';
import 'package:dekorin_apps/domain/models/collaboration.dart';

final collaborationServiceProvider = Provider<CollaborationService>((ref) {
  return CollaborationService();
});

final incomingCollaborationsProvider =
    FutureProvider.autoDispose<IncomingCollaborationsResult>((ref) async {
  return ref.read(collaborationServiceProvider).getIncomingCollaborations();
});

final agendaCollaborationsProvider =
    FutureProvider.autoDispose.family<AgendaCollaborationsResult, String>(
        (ref, agendaId) async {
  return ref.read(collaborationServiceProvider).getAgendaCollaborations(agendaId);
});

class CollaborationService {
  Future<List<CollaborationVendorOption>> searchVendors({
    String category = '',
    String query = '',
  }) async {
    final params = <String>[];
    if (category.trim().isNotEmpty) {
      params.add('category=${Uri.encodeQueryComponent(category.trim())}');
    }
    if (query.trim().isNotEmpty) {
      params.add('q=${Uri.encodeQueryComponent(query.trim())}');
    }
    final qs = params.isNotEmpty ? '?${params.join('&')}' : '';
    final res = await ApiClient.get('/collaborations/vendors$qs');
    final list = (res['data'] as List<dynamic>?) ?? const [];
    return list
        .map((e) => CollaborationVendorOption.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<AgendaCollaborationsResult> getAgendaCollaborations(String agendaId) async {
    final res = await ApiClient.get('/agendas/$agendaId/collaborations');
    final list = (res['data'] as List<dynamic>?) ?? const [];
    return AgendaCollaborationsResult(
      collaborations: list
          .map((e) => AgendaCollaboration.fromJson(e as Map<String, dynamic>))
          .toList(),
      acceptedPartnerCost: (res['accepted_partner_cost'] as num?)?.toDouble() ?? 0.0,
      pendingPartnerCost: (res['pending_partner_cost'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Future<AgendaCollaboration> invitePartner({
    required String agendaId,
    required String partnerCompanyId,
    required double partnerPrice,
    required double partnerTransportFee,
    double partnerDpAmount = 0.0,
    String notes = '',
  }) async {
    final res = await ApiClient.post(
      '/agendas/$agendaId/collaborations',
      body: {
        'partner_company_id': partnerCompanyId,
        'partner_price': partnerPrice,
        'partner_transport_fee': partnerTransportFee,
        'partner_dp_amount': partnerDpAmount,
        'notes': notes.trim(),
      },
    );
    return AgendaCollaboration.fromJson(res['data'] as Map<String, dynamic>);
  }

  Future<void> cancelCollaboration(String collaborationId) async {
    await ApiClient.delete('/collaborations/$collaborationId');
  }

  Future<IncomingCollaborationsResult> getIncomingCollaborations() async {
    final res = await ApiClient.get('/collaborations/incoming');
    final list = (res['data'] as List<dynamic>?) ?? const [];
    return IncomingCollaborationsResult(
      items: list
          .map((e) => IncomingCollaborationItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      pendingCount: (res['pending_count'] as num?)?.toInt() ?? 0,
    );
  }

  Future<AgendaCollaboration> respondCollaboration({
    required String collaborationId,
    required String action, // 'accept' or 'reject'
    String rejectReason = '',
  }) async {
    final res = await ApiClient.post(
      '/collaborations/$collaborationId/respond',
      body: {
        'action': action,
        'reject_reason': rejectReason.trim(),
      },
    );
    return AgendaCollaboration.fromJson(res['data'] as Map<String, dynamic>);
  }
}
