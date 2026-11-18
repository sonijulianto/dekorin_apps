import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:dekorin_apps/data/datasources/local/data_preferences.dart';
import 'package:dekorin_apps/data/datasources/remote/api_client.dart';
import 'package:dekorin_apps/data/datasources/remote/api_endpoint.dart';
import 'package:dekorin_apps/domain/models/chat_message.dart';
import 'package:dekorin_apps/domain/models/picked_image_data.dart';

final chatServiceProvider = Provider<ChatService>((ref) => ChatService());

final chatUnreadSummaryProvider =
    FutureProvider.autoDispose<ChatUnreadSummary>((ref) async {
  return ref.read(chatServiceProvider).getUnreadSummary();
});

final chatRoomsProvider =
    FutureProvider.autoDispose<List<ChatRoomSummary>>((ref) async {
  return ref.read(chatServiceProvider).getChatRooms();
});

class ChatService {
  Future<ChatMessagesResult> getMessages(
    String agendaId, {
    DateTime? before,
    int limit = 50,
  }) async {
    final params = <String>['limit=$limit'];
    if (before != null) {
      params.add(
        'before=${Uri.encodeQueryComponent(before.toUtc().toIso8601String())}',
      );
    }
    final res = await ApiClient.get(
      '/agendas/$agendaId/chat/messages?${params.join('&')}',
    );
    final roomJson = (res['room'] as Map<String, dynamic>?) ?? const {};
    final list = (res['messages'] as List<dynamic>?) ?? const [];
    final receipts = (res['read_receipts'] as List<dynamic>?) ?? const [];
    return ChatMessagesResult(
      room: ChatRoomInfo.fromJson(roomJson),
      messages: list
          .whereType<Map<String, dynamic>>()
          .map(ChatMessage.fromJson)
          .toList(),
      readReceipts: receipts
          .whereType<Map<String, dynamic>>()
          .map(ChatReadReceipt.fromJson)
          .toList(),
    );
  }

  Future<List<ChatRoomSummary>> getChatRooms() async {
    final res = await ApiClient.get('/chat/rooms');
    final list = (res['data'] as List<dynamic>?) ?? const [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(ChatRoomSummary.fromJson)
        .toList();
  }

  Future<ChatMessage> sendMessage(
    String agendaId, {
    required String messageType,
    String content = '',
    String attachmentUrl = '',
    String attachmentName = '',
    int attachmentSize = 0,
    String replyToId = '',
    List<String> mentionedCompanyIds = const [],
  }) async {
    final res = await ApiClient.post(
      '/agendas/$agendaId/chat/messages',
      body: {
        'message_type': messageType,
        'content': content,
        'attachment_url': attachmentUrl,
        if (attachmentName.isNotEmpty) 'attachment_name': attachmentName,
        if (attachmentSize > 0) 'attachment_size': attachmentSize,
        if (replyToId.isNotEmpty) 'reply_to_id': replyToId,
        if (mentionedCompanyIds.isNotEmpty)
          'mentioned_company_ids': mentionedCompanyIds,
      },
    );
    return ChatMessage.fromJson(
      (res['data'] as Map<String, dynamic>?) ?? const {},
    );
  }

  Future<String> uploadChatImage(String agendaId, PickedImageData image) async {
    final res = await ApiClient.uploadMultipart(
      '/agendas/$agendaId/chat/upload',
      fileField: 'file',
      image: image,
      timeout: const Duration(seconds: 45),
      timeoutMessage:
          'Gagal mengunggah foto diskusi (timeout). Periksa koneksi internet Anda.',
    );
    return (res['url'] as String?) ?? '';
  }

  Future<Map<String, dynamic>> uploadChatPdf(
    String agendaId, {
    required Uint8List bytes,
    required String filename,
  }) async {
    final uri = Uri.parse('${ApiEndpoint.baseUrl}/agendas/$agendaId/chat/upload');
    final request = http.MultipartRequest('POST', uri);
    final token = DataPreferences.getToken();
    if (token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.files.add(
      http.MultipartFile.fromBytes('file', bytes, filename: filename),
    );
    final streamed = await request.send().timeout(const Duration(seconds: 60));
    final response = await http.Response.fromStream(streamed);
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(decoded['error'] ?? 'Gagal mengunggah file PDF');
    }
    return decoded;
  }

  Future<void> markAsRead(String agendaId) async {
    await ApiClient.post('/agendas/$agendaId/chat/read');
  }

  Future<List<ChatCrewOption>> getCrewOptions(String agendaId) async {
    final res = await ApiClient.get('/agendas/$agendaId/chat/crew');
    final list = (res['data'] as List<dynamic>?) ?? const [];
    return list
        .whereType<Map<String, dynamic>>()
        .map(ChatCrewOption.fromJson)
        .toList();
  }

  Future<void> updateCrewAssignments(
    String agendaId,
    List<String> userIds,
  ) async {
    await ApiClient.post(
      '/agendas/$agendaId/chat/crew',
      body: {'user_ids': userIds},
    );
  }

  Future<ChatUnreadSummary> getUnreadSummary() async {
    try {
      final res = await ApiClient.get('/chat/unread-counts');
      final rawCounts =
          (res['unread_counts'] as Map<String, dynamic>?) ?? const {};
      final counts = <String, int>{};
      rawCounts.forEach((k, v) {
        counts[k] = (v as num?)?.toInt() ?? 0;
      });
      final rawActive = (res['active_agendas'] as List<dynamic>?) ?? const [];
      final active = rawActive.map((e) => e.toString()).toSet();
      return ChatUnreadSummary(
        unreadCounts: counts,
        activeAgendas: active,
      );
    } catch (_) {
      return const ChatUnreadSummary();
    }
  }

  /// Membuka koneksi WebSocket ke room diskusi agenda.
  WebSocketChannel connectWebSocket(String agendaId) {
    final token = DataPreferences.getToken();
    final baseUri = Uri.parse(ApiEndpoint.baseUrl);
    final wsScheme = baseUri.scheme == 'https' ? 'wss' : 'ws';
    final wsPath = '${baseUri.path}/ws/agendas/$agendaId/chat';
    final wsUri = Uri(
      scheme: wsScheme,
      host: baseUri.host,
      port: baseUri.hasPort ? baseUri.port : null,
      path: wsPath,
      queryParameters: {'token': token},
    );
    return WebSocketChannel.connect(wsUri);
  }
}
