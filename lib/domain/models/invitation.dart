import 'package:flutter/material.dart';

/// Pilihan Template Desain Undangan Digital
class InvitationTemplate {
  static const String greenLeaves = 'green-leaves';
  static const String creamyLatte = 'creamy-latte';
  static const String floral = 'floral';
  static const String luxuryGrey = 'luxury-grey';
  static const String khitanGreen = 'khitan-green';

  static const List<Map<String, dynamic>> all = [
    {
      'id': greenLeaves,
      'name': 'Green Leaves',
      'tag': 'Natural & Asri',
      'description': 'Nuansa dedaunan hijau alami yang segar, menyejukkan, dan asri.',
      'primaryColor': Color(0xFF588157),
      'secondaryColor': Color(0xFF3A5A40),
      'backgroundColor': Color(0xFFF4F7F4),
      'accentColor': Color(0xFFA3B18A),
      'eventType': 'wedding',
    },
    {
      'id': creamyLatte,
      'name': 'Creamy Latte',
      'tag': 'Warm & Timeless',
      'description': 'Warna krem dan earthy hangat yang klasik, tenang, dan bersahaja.',
      'primaryColor': Color(0xFFB4846C),
      'secondaryColor': Color(0xFF7D5A50),
      'backgroundColor': Color(0xFFFAF5EF),
      'accentColor': Color(0xFFE5B299),
      'eventType': 'wedding',
    },
    {
      'id': floral,
      'name': 'Floral Terracotta',
      'tag': 'Romantic & Soft',
      'description': 'Sentuhan bunga mekar yang lembut dan romantis bernuansa terracotta.',
      'primaryColor': Color(0xFFD47A60),
      'secondaryColor': Color(0xFF8E443D),
      'backgroundColor': Color(0xFFFDF8F5),
      'accentColor': Color(0xFFF4A261),
      'eventType': 'wedding',
    },
    {
      'id': luxuryGrey,
      'name': 'Luxury Grey',
      'tag': 'Modern & Dark Luxury',
      'description': 'Monokrom abu-abu gelap dan charcoal eksklusif berpadu emas mewah.',
      'primaryColor': Color(0xFFD4A574),
      'secondaryColor': Color(0xFF2C3333),
      'backgroundColor': Color(0xFF1E2022),
      'accentColor': Color(0xFFECDFCC),
      'eventType': 'wedding',
    },
    {
      'id': khitanGreen,
      'name': 'Khitan Green',
      'tag': 'Tasyakuran Khitan',
      'description': 'Tema khusus tasyakuran khitanan anak dengan ornamen islami hijau zamrud.',
      'primaryColor': Color(0xFF2E8B57),
      'secondaryColor': Color(0xFF1B4D3E),
      'backgroundColor': Color(0xFFF0F7F4),
      'accentColor': Color(0xFFC1E1C1),
      'eventType': 'khitan',
    },
  ];

  static Map<String, dynamic> getById(String id) {
    return all.firstWhere(
      (t) => t['id'] == id,
      orElse: () => all.first,
    );
  }
}

class InvitationItem {
  const InvitationItem({
    required this.id,
    required this.slug,
    required this.title,
    this.template = 'green-leaves',
    this.eventType = 'wedding',
    this.coverImage = '',
    this.quotes = '',
    required this.groomName,
    this.groomNickname = '',
    this.groomChildOrder = '',
    this.groomParents = '',
    this.groomInstagram = '',
    this.groomPhoto = '',
    required this.brideName,
    this.brideNickname = '',
    this.brideChildOrder = '',
    this.brideParents = '',
    this.brideInstagram = '',
    this.bridePhoto = '',
    this.childName = '',
    this.childNickname = '',
    this.childOrder = '',
    this.akadDate = '',
    this.akadTime = '',
    this.akadVenue = '',
    this.akadAddress = '',
    this.akadMapsUrl = '',
    this.resepsiDate = '',
    this.resepsiTime = '',
    this.resepsiVenue = '',
    this.resepsiAddress = '',
    this.resepsiMapsUrl = '',
    this.bankName1 = '',
    this.bankAccount1 = '',
    this.bankHolder1 = '',
    this.bankName2 = '',
    this.bankAccount2 = '',
    this.bankHolder2 = '',
    this.giftAddress = '',
    this.waConfirmation = '',
    this.audioUrl = '',
    this.galleryImages = '',
    this.youtubeUrl = '',
    this.loveStory = '',
    this.turutMengundang = '',
    this.sec1Photo = '',
    this.akadPhoto = '',
    this.resepsiPhoto = '',
    this.eventPhoto = '',
    this.closingPhoto = '',
    this.isActive = true,
    this.createdAt,
    this.wishes = const [],
  });

  final String id;
  final String slug;
  final String title;
  final String template;
  final String eventType;
  final String coverImage;
  final String quotes;
  final String groomName;
  final String groomNickname;
  final String groomChildOrder;
  final String groomParents;
  final String groomInstagram;
  final String groomPhoto;
  final String brideName;
  final String brideNickname;
  final String brideChildOrder;
  final String brideParents;
  final String brideInstagram;
  final String bridePhoto;
  final String childName;
  final String childNickname;
  final String childOrder;
  final String akadDate;
  final String akadTime;
  final String akadVenue;
  final String akadAddress;
  final String akadMapsUrl;
  final String resepsiDate;
  final String resepsiTime;
  final String resepsiVenue;
  final String resepsiAddress;
  final String resepsiMapsUrl;
  final String bankName1;
  final String bankAccount1;
  final String bankHolder1;
  final String bankName2;
  final String bankAccount2;
  final String bankHolder2;
  final String giftAddress;
  final String waConfirmation;
  final String audioUrl;
  final String galleryImages;
  final String youtubeUrl;
  final String loveStory;
  final String turutMengundang;
  final String sec1Photo;
  final String akadPhoto;
  final String resepsiPhoto;
  final String eventPhoto;
  final String closingPhoto;
  final bool isActive;
  final DateTime? createdAt;
  final List<InvitationWishItem> wishes;

  factory InvitationItem.fromJson(Map<String, dynamic> json) {
    var rawWishes = json['wishes'] as List<dynamic>? ?? [];
    List<InvitationWishItem> wishesList = rawWishes
        .map((w) => InvitationWishItem.fromJson(w as Map<String, dynamic>))
        .toList();

    return InvitationItem(
      id: json['id'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      title: json['title'] as String? ?? '',
      template: json['template'] as String? ?? 'green-leaves',
      eventType: json['event_type'] as String? ?? 'wedding',
      coverImage: json['cover_image'] as String? ?? '',
      quotes: json['quotes'] as String? ?? '',
      groomName: json['groom_name'] as String? ?? '',
      groomNickname: json['groom_nickname'] as String? ?? '',
      groomChildOrder: json['groom_child_order'] as String? ?? '',
      groomParents: json['groom_parents'] as String? ?? '',
      groomInstagram: json['groom_instagram'] as String? ?? '',
      groomPhoto: json['groom_photo'] as String? ?? '',
      brideName: json['bride_name'] as String? ?? '',
      brideNickname: json['bride_nickname'] as String? ?? '',
      brideChildOrder: json['bride_child_order'] as String? ?? '',
      brideParents: json['bride_parents'] as String? ?? '',
      brideInstagram: json['bride_instagram'] as String? ?? '',
      bridePhoto: json['bride_photo'] as String? ?? '',
      childName: json['child_name'] as String? ?? '',
      childNickname: json['child_nickname'] as String? ?? '',
      childOrder: json['child_order'] as String? ?? '',
      akadDate: json['akad_date'] as String? ?? '',
      akadTime: json['akad_time'] as String? ?? '',
      akadVenue: json['akad_venue'] as String? ?? '',
      akadAddress: json['akad_address'] as String? ?? '',
      akadMapsUrl: json['akad_maps_url'] as String? ?? '',
      resepsiDate: json['resepsi_date'] as String? ?? '',
      resepsiTime: json['resepsi_time'] as String? ?? '',
      resepsiVenue: json['resepsi_venue'] as String? ?? '',
      resepsiAddress: json['resepsi_address'] as String? ?? '',
      resepsiMapsUrl: json['resepsi_maps_url'] as String? ?? '',
      bankName1: json['bank_name_1'] as String? ?? '',
      bankAccount1: json['bank_account_1'] as String? ?? '',
      bankHolder1: json['bank_holder_1'] as String? ?? '',
      bankName2: json['bank_name_2'] as String? ?? '',
      bankAccount2: json['bank_account_2'] as String? ?? '',
      bankHolder2: json['bank_holder_2'] as String? ?? '',
      giftAddress: json['gift_address'] as String? ?? '',
      waConfirmation: json['wa_confirmation'] as String? ?? '',
      audioUrl: json['audio_url'] as String? ?? '',
      galleryImages: json['gallery_images'] as String? ?? '',
      youtubeUrl: json['youtube_url'] as String? ?? '',
      loveStory: json['love_story'] as String? ?? '',
      turutMengundang: json['turut_mengundang'] as String? ?? '',
      sec1Photo: json['sec1_photo'] as String? ?? '',
      akadPhoto: json['akad_photo'] as String? ?? '',
      resepsiPhoto: json['resepsi_photo'] as String? ?? '',
      eventPhoto: json['event_photo'] as String? ?? '',
      closingPhoto: json['closing_photo'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      wishes: wishesList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'slug': slug,
      'title': title,
      'template': template,
      'event_type': eventType,
      'cover_image': coverImage,
      'quotes': quotes,
      'groom_name': groomName,
      'groom_nickname': groomNickname,
      'groom_child_order': groomChildOrder,
      'groom_parents': groomParents,
      'groom_instagram': groomInstagram,
      'groom_photo': groomPhoto,
      'bride_name': brideName,
      'bride_nickname': brideNickname,
      'bride_child_order': brideChildOrder,
      'bride_parents': brideParents,
      'bride_instagram': brideInstagram,
      'bride_photo': bridePhoto,
      'child_name': childName,
      'child_nickname': childNickname,
      'child_order': childOrder,
      'akad_date': akadDate,
      'akad_time': akadTime,
      'akad_venue': akadVenue,
      'akad_address': akadAddress,
      'akad_maps_url': akadMapsUrl,
      'resepsi_date': resepsiDate,
      'resepsi_time': resepsiTime,
      'resepsi_venue': resepsiVenue,
      'resepsi_address': resepsiAddress,
      'resepsi_maps_url': resepsiMapsUrl,
      'bank_name_1': bankName1,
      'bank_account_1': bankAccount1,
      'bank_holder_1': bankHolder1,
      'bank_name_2': bankName2,
      'bank_account_2': bankAccount2,
      'bank_holder_2': bankHolder2,
      'gift_address': giftAddress,
      'wa_confirmation': waConfirmation,
      'audio_url': audioUrl,
      'gallery_images': galleryImages,
      'youtube_url': youtubeUrl,
      'love_story': loveStory,
      'turut_mengundang': turutMengundang,
      'sec1_photo': sec1Photo,
      'akad_photo': akadPhoto,
      'resepsi_photo': resepsiPhoto,
      'event_photo': eventPhoto,
      'closing_photo': closingPhoto,
      'is_active': isActive,
    };
  }
}

class InvitationWishItem {
  const InvitationWishItem({
    required this.id,
    required this.invitationId,
    required this.guestName,
    this.attendance = 'hadir',
    this.guestCount = 1,
    required this.message,
    this.createdAt,
  });

  final String id;
  final String invitationId;
  final String guestName;
  final String attendance;
  final int guestCount;
  final String message;
  final DateTime? createdAt;

  factory InvitationWishItem.fromJson(Map<String, dynamic> json) {
    return InvitationWishItem(
      id: json['id'] as String? ?? '',
      invitationId: json['invitation_id'] as String? ?? '',
      guestName: json['guest_name'] as String? ?? '',
      attendance: json['attendance'] as String? ?? 'hadir',
      guestCount: (json['guest_count'] as num?)?.toInt() ?? 1,
      message: json['message'] as String? ?? '',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }
}
