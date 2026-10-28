class DecorationModel {
  const DecorationModel({
    required this.id,
    this.brandId = '',
    this.brandName = '',
    required this.name,
    required this.width,
    required this.price,
    this.description = '',
    this.imageUrl = '',
    this.sortOrder = 0,
  });

  final String id;
  final String brandId;
  final String brandName;
  final String name;
  final String width;
  final double price;
  final String description;
  final String imageUrl;
  final int sortOrder;

  factory DecorationModel.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    return DecorationModel(
      id: json['id'] as String? ?? '',
      brandId: json['brand_id'] as String? ?? '',
      brandName: json['brand_name'] as String? ?? '',
      name: json['name'] as String? ?? '',
      width: json['width'] as String? ?? '',
      price: parseDouble(json['price']),
      description: json['description'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'brand_id': brandId,
      'brand_name': brandName,
      'name': name,
      'width': width,
      'price': price,
      'description': description,
      'image_url': imageUrl,
      'sort_order': sortOrder,
    };
  }

  DecorationModel copyWith({
    String? id,
    String? brandId,
    String? brandName,
    String? name,
    String? width,
    double? price,
    String? description,
    String? imageUrl,
    int? sortOrder,
  }) {
    return DecorationModel(
      id: id ?? this.id,
      brandId: brandId ?? this.brandId,
      brandName: brandName ?? this.brandName,
      name: name ?? this.name,
      width: width ?? this.width,
      price: price ?? this.price,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DecorationModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
