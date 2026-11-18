class ChatParticipant {
  final String companyId;
  final String companyName;
  final String category;
  final bool isLead;

  const ChatParticipant({
    required this.companyId,
    required this.companyName,
    required this.category,
    required this.isLead,
  });

  factory ChatParticipant.fromJson(Map<String, dynamic> json) {
    return ChatParticipant(
      companyId: (json['company_id'] as String?) ?? '',
      companyName: (json['company_name'] as String?) ?? '',
      category: (json['category'] as String?) ?? '',
      isLead: json['is_lead'] == true,
    );
  }
}

class ChatRoomInfo {
  final String id;
  final String leadAgendaId;
  final String clientName;
  final String eventLabel;
  final String eventType;
  final DateTime? eventDateTime;
  final String eventAddress;
  final String mapsUrl;
  final List<ChatParticipant> participants;
  final bool canManageCrew;

  const ChatRoomInfo({
    required this.id,
    required this.leadAgendaId,
    required this.clientName,
    required this.eventLabel,
    required this.eventType,
    this.eventDateTime,
    required this.eventAddress,
    required this.mapsUrl,
    required this.participants,
    required this.canManageCrew,
  });

  factory ChatRoomInfo.fromJson(Map<String, dynamic> json) {
    final rawParticipants = (json['participants'] as List<dynamic>?) ?? const [];
    return ChatRoomInfo(
      id: (json['id'] as String?) ?? '',
      leadAgendaId: (json['lead_agenda_id'] as String?) ?? '',
      clientName: (json['client_name'] as String?) ?? '',
      eventLabel: (json['event_label'] as String?) ?? '',
      eventType: (json['event_type'] as String?) ?? '',
      eventDateTime: DateTime.tryParse((json['event_date_time'] as String?) ?? ''),
      eventAddress: (json['event_address'] as String?) ?? '',
      mapsUrl: (json['maps_url'] as String?) ?? '',
      participants: rawParticipants
          .whereType<Map<String, dynamic>>()
          .map(ChatParticipant.fromJson)
          .toList(),
      canManageCrew: json['can_manage_crew'] == true,
    );
  }
}

class ChatMessage {
  final String id;
  final String roomId;
  final String senderUserId;
  final String senderCompanyId;
  final String senderCompanyName;
  final String senderCategory;
  final String senderName;
  final String senderRole;
  final String messageType; // text | image | file | system
  final String content;
  final String attachmentUrl;
  final String attachmentName;
  final int attachmentSize;
  final String replyToId;
  final String replySenderName;
  final String replyPreview;
  final List<String> mentionedCompanyIds;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.roomId,
    required this.senderUserId,
    required this.senderCompanyId,
    required this.senderCompanyName,
    required this.senderCategory,
    required this.senderName,
    required this.senderRole,
    required this.messageType,
    required this.content,
    required this.attachmentUrl,
    this.attachmentName = '',
    this.attachmentSize = 0,
    this.replyToId = '',
    this.replySenderName = '',
    this.replyPreview = '',
    this.mentionedCompanyIds = const [],
    required this.createdAt,
  });

  bool get isSystem => messageType == 'system';
  bool get isImage => messageType == 'image';
  bool get isFile => messageType == 'file';

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final rawMentions = (json['mentioned_company_ids'] as String?) ?? '';
    final mentions = rawMentions
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    return ChatMessage(
      id: (json['id'] as String?) ?? '',
      roomId: (json['room_id'] as String?) ?? '',
      senderUserId: (json['sender_user_id'] as String?) ?? '',
      senderCompanyId: (json['sender_company_id'] as String?) ?? '',
      senderCompanyName: (json['sender_company_name'] as String?) ?? '',
      senderCategory: (json['sender_category'] as String?) ?? '',
      senderName: (json['sender_name'] as String?) ?? '',
      senderRole: (json['sender_role'] as String?) ?? '',
      messageType: (json['message_type'] as String?) ?? 'text',
      content: (json['content'] as String?) ?? '',
      attachmentUrl: (json['attachment_url'] as String?) ?? '',
      attachmentName: (json['attachment_name'] as String?) ?? '',
      attachmentSize: (json['attachment_size'] as num?)?.toInt() ?? 0,
      replyToId: (json['reply_to_id'] as String?) ?? '',
      replySenderName: (json['reply_sender_name'] as String?) ?? '',
      replyPreview: (json['reply_preview'] as String?) ?? '',
      mentionedCompanyIds: mentions,
      createdAt:
          DateTime.tryParse((json['created_at'] as String?) ?? '') ?? DateTime.now(),
    );
  }
}

class ChatReadReceipt {
  final String userId;
  final String userName;
  final String companyId;
  final String companyName;
  final DateTime lastReadAt;

  const ChatReadReceipt({
    required this.userId,
    required this.userName,
    required this.companyId,
    required this.companyName,
    required this.lastReadAt,
  });

  factory ChatReadReceipt.fromJson(Map<String, dynamic> json) {
    return ChatReadReceipt(
      userId: (json['user_id'] as String?) ?? '',
      userName: (json['user_name'] as String?) ?? '',
      companyId: (json['company_id'] as String?) ?? '',
      companyName: (json['company_name'] as String?) ?? '',
      lastReadAt:
          DateTime.tryParse((json['last_read_at'] as String?) ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class ChatMessagesResult {
  final ChatRoomInfo room;
  final List<ChatMessage> messages;
  final List<ChatReadReceipt> readReceipts;

  const ChatMessagesResult({
    required this.room,
    required this.messages,
    this.readReceipts = const [],
  });
}

class ChatCrewOption {
  final String userId;
  final String name;
  final String phone;
  final String role;
  final bool isAssigned;

  const ChatCrewOption({
    required this.userId,
    required this.name,
    required this.phone,
    required this.role,
    required this.isAssigned,
  });

  factory ChatCrewOption.fromJson(Map<String, dynamic> json) {
    return ChatCrewOption(
      userId: (json['user_id'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      phone: (json['phone'] as String?) ?? '',
      role: (json['role'] as String?) ?? 'crew',
      isAssigned: json['is_assigned'] == true,
    );
  }
}

class ChatUnreadSummary {
  final Map<String, int> unreadCounts;
  final Set<String> activeAgendas;

  const ChatUnreadSummary({
    this.unreadCounts = const {},
    this.activeAgendas = const {},
  });

  int unreadFor(String agendaId) => unreadCounts[agendaId] ?? 0;
  bool isActiveFor(String agendaId) => activeAgendas.contains(agendaId);
  int get totalUnread => unreadCounts.values.fold(0, (a, b) => a + b);
}

class ChatRoomSummary {
  final String roomId;
  final String agendaId;
  final String leadAgendaId;
  final String clientName;
  final String eventLabel;
  final DateTime? eventDateTime;
  final DateTime? lastMessageAt;
  final String lastMessagePreview;
  final String lastSenderName;
  final int unreadCount;
  final List<String> partnerNames;

  const ChatRoomSummary({
    required this.roomId,
    required this.agendaId,
    required this.leadAgendaId,
    required this.clientName,
    required this.eventLabel,
    this.eventDateTime,
    this.lastMessageAt,
    required this.lastMessagePreview,
    required this.lastSenderName,
    required this.unreadCount,
    required this.partnerNames,
  });

  factory ChatRoomSummary.fromJson(Map<String, dynamic> json) {
    final rawPartners = (json['partner_names'] as List<dynamic>?) ?? const [];
    return ChatRoomSummary(
      roomId: (json['room_id'] as String?) ?? '',
      agendaId: (json['agenda_id'] as String?) ?? '',
      leadAgendaId: (json['lead_agenda_id'] as String?) ?? '',
      clientName: (json['client_name'] as String?) ?? '',
      eventLabel: (json['event_label'] as String?) ?? '',
      eventDateTime: DateTime.tryParse((json['event_date_time'] as String?) ?? ''),
      lastMessageAt: DateTime.tryParse((json['last_message_at'] as String?) ?? ''),
      lastMessagePreview: (json['last_message_preview'] as String?) ?? '',
      lastSenderName: (json['last_sender_name'] as String?) ?? '',
      unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
      partnerNames: rawPartners.map((e) => e.toString()).toList(),
    );
  }
}
