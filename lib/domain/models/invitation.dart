import 'package:flutter/material.dart';

/// Kategori Acara untuk Undangan Digital
class InvitationEventCategory {
  static const String wedding = 'wedding';
  static const String khitan = 'khitan';
  static const String birthday = 'birthday';
  static const String engagement = 'engagement';
  static const String aqiqah = 'aqiqah';
  static const String graduation = 'graduation';
  static const String housewarming = 'housewarming';
  static const String gathering = 'gathering';

  static const List<Map<String, dynamic>> all = [
    {
      'id': wedding,
      'name': 'Pernikahan (Wedding)',
      'shortName': 'Pernikahan',
      'icon': '💍',
      'description': 'Undangan pernikahan kedua mempelai lengkap dengan akad, resepsi, dan cerita cinta.',
    },
    {
      'id': khitan,
      'name': 'Tasyakuran Khitanan',
      'shortName': 'Khitanan',
      'icon': '🕌',
      'description': 'Undangan tasyakuran khitanan anak dengan data anak & orang tua, doa tasyakuran.',
    },
    {
      'id': birthday,
      'name': 'Ulang Tahun (Birthday)',
      'shortName': 'Ulang Tahun',
      'icon': '🎂',
      'description': 'Undangan pesta perayaan ulang tahun ceria dan penuh kebahagiaan.',
    },
    {
      'id': engagement,
      'name': 'Lamaran / Tunangan',
      'shortName': 'Lamaran',
      'icon': '💐',
      'description': 'Undangan prosesi lamaran & pertemuan keluarga besar kedua calon mempelai.',
    },
    {
      'id': aqiqah,
      'name': 'Aqiqah & Kelahiran',
      'shortName': 'Aqiqah',
      'icon': '👶',
      'description': 'Undangan syukuran aqiqah dan tasyakuran kelahiran putra/putri tercinta.',
    },
    {
      'id': graduation,
      'name': 'Wisuda & Kelulusan',
      'shortName': 'Wisuda',
      'icon': '🎓',
      'description': 'Undangan syukuran kelulusan atau perayaan wisuda sarjana.',
    },
    {
      'id': housewarming,
      'name': 'Syukuran Rumah Baru',
      'shortName': 'Rumah Baru',
      'icon': '🏡',
      'description': 'Undangan selamatan menempati kediaman atau kantor baru.',
    },
    {
      'id': gathering,
      'name': 'Reuni & Gathering',
      'shortName': 'Gathering',
      'icon': '🤝',
      'description': 'Undangan temu kangen alumni, gathering keluarga, atau komunitas.',
    },
  ];

  static Map<String, dynamic> getById(String id) {
    return all.firstWhere(
      (c) => c['id'] == id,
      orElse: () => all.first, // wedding
    );
  }

  /// Mengambil daftar kategori acara yang aktif / memiliki minimal 1 template yang mendukung
  static List<Map<String, dynamic>> getAvailableCategories() {
    final availableCategoryIds = <String>{};
    for (final tmpl in InvitationTemplate.all) {
      if (tmpl['supportedCategories'] is List) {
        for (final cat in tmpl['supportedCategories'] as List) {
          availableCategoryIds.add(cat.toString());
        }
      } else if (tmpl['category'] is String) {
        availableCategoryIds.add(tmpl['category'] as String);
      }
    }

    return all.where((c) => availableCategoryIds.contains(c['id'])).toList();
  }
}

/// Pilihan Template Desain Undangan Digital (Monochrome PN4, Sakura Blossom TA3, Ocean Blossom TA17, Art Jawa Coklat 3, Art Jawa Biru 2)
class InvitationTemplate {
  static const String ta17 = 'ta17';
  static const String ta3 = 'ta3';
  static const String pn4 = 'pn4';
  static const String jawa3 = 'jawa3';
  static const String jawa2 = 'jawa2';

  static const List<Map<String, dynamic>> all = [
    {
      'id': ta17,
      'name': 'Ocean Blossom TA17',
      'tag': 'Pastel Blue & Floral',
      'category': 'wedding',
      'categoryName': 'Pernikahan',
      'supportedCategories': ['wedding'],
      'description': 'Desain floral biru pastel elegan dengan bingkai lengkung, countdown, dan love story.',
      'primaryColor': Color(0xFF4B8DCB),
      'secondaryColor': Color(0xFF295177),
      'backgroundColor': Color(0xFFF0F6FC),
      'accentColor': Color(0xFFA4C8EB),
      'eventType': 'wedding',
    },
    {
      'id': jawa3,
      'name': 'Art Jawa Coklat 3',
      'tag': 'Javanese Royal & Wayang',
      'category': 'wedding',
      'categoryName': 'Pernikahan',
      'supportedCategories': ['wedding', 'khitan'],
      'description': 'Desain adat Jawa keraton klasik dengan gunungan wayang emas, animasi air, bingkai oval, dan kisah cinta.',
      'primaryColor': Color(0xFFAC9271),
      'secondaryColor': Color(0xFF4F2323),
      'backgroundColor': Color(0xFFFFFCF3),
      'accentColor': Color(0xFFD7BB83),
      'eventType': 'wedding',
    },
    {
      'id': jawa2,
      'name': 'Art Jawa Biru 2',
      'tag': 'Javanese Royal Blue & Wayang',
      'category': 'wedding',
      'categoryName': 'Pernikahan',
      'supportedCategories': ['wedding', 'khitan'],
      'description': 'Desain adat Jawa biru keraton elegan dengan gunungan wayang biru, animasi air, bingkai lengkung (arch), dan kisah cinta.',
      'primaryColor': Color(0xFF284B73),
      'secondaryColor': Color(0xFF1B3554),
      'backgroundColor': Color(0xFFF6F8FB),
      'accentColor': Color(0xFF6EC1E4),
      'eventType': 'wedding',
    },
    {
      'id': ta3,
      'name': 'Sakura Blossom TA3',
      'tag': 'Romantic Floral & Arch',
      'category': 'wedding',
      'categoryName': 'Pernikahan',
      'supportedCategories': ['wedding'],
      'description': 'Desain floral sakura romantis dengan bingkai lengkung, countdown, dan love story.',
      'primaryColor': Color(0xFFD4A373),
      'secondaryColor': Color(0xFFC08081),
      'backgroundColor': Color(0xFFFFF9F9),
      'accentColor': Color(0xFFFDE8E9),
      'eventType': 'wedding',
    },
    {
      'id': pn4,
      'name': 'Monochrome PN4',
      'tag': 'Editorial Monochrome',
      'category': 'wedding',
      'categoryName': 'Pernikahan',
      'supportedCategories': ['wedding'],
      'description': 'Desain editorial monokrom elegan dengan frame lengkung & tipografi klasik.',
      'primaryColor': Color(0xFF343434),
      'secondaryColor': Color(0xFF6E6E6E),
      'backgroundColor': Color(0xFFF1F1F1),
      'accentColor': Color(0xFFFFFFFF),
      'eventType': 'wedding',
    },
  ];

  static Map<String, dynamic> getById(String id) {
    return all.firstWhere(
      (t) => t['id'] == id,
      orElse: () => all.first, // Default ke Ocean Blossom TA17
    );
  }

  /// Mengambil template yang mendukung kategori tertentu.
  /// Jika categoryId == 'all', kembalikan semua template.
  static List<Map<String, dynamic>> getByCategory(String categoryId) {
    if (categoryId == 'all') return all;
    return all.where((tmpl) {
      final supported = tmpl['supportedCategories'] as List?;
      if (supported != null && supported.contains(categoryId)) {
        return true;
      }
      return tmpl['category'] == categoryId;
    }).toList();
  }
}

class InvitationItem {
  const InvitationItem({
    required this.id,
    required this.slug,
    required this.title,
    this.template = 'ta17',
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
    this.editToken = '',
    this.editPin = '',
    this.isActive = true,
    this.createdAt,
    this.wishes = const [],
    this.wishesCount = 0,
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
  final String editToken;
  final String editPin;
  final bool isActive;
  final DateTime? createdAt;
  final List<InvitationWishItem> wishes;
  final int wishesCount;

  factory InvitationItem.fromJson(Map<String, dynamic> json) {
    var rawWishes = json['wishes'] as List<dynamic>? ?? [];
    List<InvitationWishItem> wishesList = rawWishes
        .map((w) => InvitationWishItem.fromJson(w as Map<String, dynamic>))
        .toList();

    return InvitationItem(
      id: json['id'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      title: json['title'] as String? ?? '',
      template: json['template'] as String? ?? 'ta17',
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
      editToken: json['edit_token'] as String? ?? '',
      editPin: json['edit_pin'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
      wishes: wishesList,
      wishesCount: (json['wishes_count'] as num?)?.toInt() ?? wishesList.length,
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
