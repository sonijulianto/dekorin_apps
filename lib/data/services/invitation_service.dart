import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dekorin_apps/data/datasources/remote/api_client.dart';
import 'package:dekorin_apps/data/datasources/remote/api_endpoint.dart';
import 'package:dekorin_apps/domain/models/invitation.dart';

final invitationServiceProvider = Provider<InvitationService>((ref) {
  return InvitationService();
});

class InvitationService {
  /// Mengambil semua daftar undangan digital
  Future<List<InvitationItem>> getInvitations() async {
    try {
      final res = await ApiClient.get(ApiEndpoint.invitations);
      final List<dynamic> data = res['data'] as List<dynamic>? ?? [];
      return data.map((item) => InvitationItem.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Mengambil detail 1 undangan lengkap dengan wishes
  Future<InvitationItem?> getInvitation(String id) async {
    try {
      final res = await ApiClient.get('${ApiEndpoint.invitations}/$id');
      return InvitationItem.fromJson(res['data'] as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Membuat undangan digital baru
  Future<InvitationItem> createInvitation(Map<String, dynamic> payload) async {
    final res = await ApiClient.post(ApiEndpoint.invitations, body: payload);
    return InvitationItem.fromJson(res['data'] as Map<String, dynamic>);
  }

  /// Memperbarui undangan digital
  Future<InvitationItem> updateInvitation(String id, Map<String, dynamic> payload) async {
    final res = await ApiClient.put('${ApiEndpoint.invitations}/$id', body: payload);
    return InvitationItem.fromJson(res['data'] as Map<String, dynamic>);
  }

  /// Menghapus undangan digital
  Future<void> deleteInvitation(String id) async {
    await ApiClient.delete('${ApiEndpoint.invitations}/$id');
  }

  /// Mengambil daftar ucapan / wishes tamu untuk suatu undangan
  Future<List<InvitationWishItem>> getWishes(String invitationId) async {
    try {
      final res = await ApiClient.get('${ApiEndpoint.invitations}/$invitationId/wishes');
      final List<dynamic> data = res['data'] as List<dynamic>? ?? [];
      return data.map((w) => InvitationWishItem.fromJson(w as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }
}
