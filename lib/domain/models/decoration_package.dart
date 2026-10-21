class DecorationPackage {
  const DecorationPackage({
    required this.id,
    required this.name,
    required this.description,
    required this.basePrice,
    this.imageUrl = '',
    this.sortOrder = 0,
  });

  final String id;
  final String name;
  final String description;
  final double basePrice;
  final String imageUrl;
  final int sortOrder;

  factory DecorationPackage.fromJson(Map<String, dynamic> json) {
    return DecorationPackage(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
      basePrice: (json['base_price'] is num)
          ? (json['base_price'] as num).toDouble()
          : double.tryParse(json['base_price']?.toString() ?? '0') ?? 0.0,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'image_url': imageUrl,
      'base_price': basePrice,
      'sort_order': sortOrder,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DecorationPackage &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
