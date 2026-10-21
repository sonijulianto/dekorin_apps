class InvitationItem {
  const InvitationItem({
    required this.id,
    required this.slug,
    required this.title,
    this.coverImage = '',
    this.quotes = '',
    required this.groomName,
    this.groomNickname = '',
    this.groomParents = '',
    this.groomInstagram = '',
    this.groomPhoto = '',
    required this.brideName,
    this.brideNickname = '',
    this.brideParents = '',
    this.brideInstagram = '',
    this.bridePhoto = '',
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
    this.audioUrl = '',
    this.galleryImages = '',
    this.isActive = true,
    this.createdAt,
    this.wishes = const [],
  });

  final String id;
  final String slug;
  final String title;
  final String coverImage;
  final String quotes;
  final String groomName;
  final String groomNickname;
  final String groomParents;
  final String groomInstagram;
  final String groomPhoto;
  final String brideName;
  final String brideNickname;
  final String brideParents;
  final String brideInstagram;
  final String bridePhoto;
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
  final String audioUrl;
  final String galleryImages;
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
      coverImage: json['cover_image'] as String? ?? '',
      quotes: json['quotes'] as String? ?? '',
      groomName: json['groom_name'] as String? ?? '',
      groomNickname: json['groom_nickname'] as String? ?? '',
      groomParents: json['groom_parents'] as String? ?? '',
      groomInstagram: json['groom_instagram'] as String? ?? '',
      groomPhoto: json['groom_photo'] as String? ?? '',
      brideName: json['bride_name'] as String? ?? '',
      brideNickname: json['bride_nickname'] as String? ?? '',
      brideParents: json['bride_parents'] as String? ?? '',
      brideInstagram: json['bride_instagram'] as String? ?? '',
      bridePhoto: json['bride_photo'] as String? ?? '',
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
      audioUrl: json['audio_url'] as String? ?? '',
      galleryImages: json['gallery_images'] as String? ?? '',
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
      'cover_image': coverImage,
      'quotes': quotes,
      'groom_name': groomName,
      'groom_nickname': groomNickname,
      'groom_parents': groomParents,
      'groom_instagram': groomInstagram,
      'groom_photo': groomPhoto,
      'bride_name': brideName,
      'bride_nickname': brideNickname,
      'bride_parents': brideParents,
      'bride_instagram': brideInstagram,
      'bride_photo': bridePhoto,
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
      'audio_url': audioUrl,
      'gallery_images': galleryImages,
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
