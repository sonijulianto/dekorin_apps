class DecorationAddon {
  const DecorationAddon({
    required this.id,
    required this.name,
    required this.price,
    this.description = '',
    this.imageUrl = '',
  });

  final String id;
  final String name;
  final double price;
  final String description;
  final String imageUrl;

  factory DecorationAddon.fromJson(Map<String, dynamic> json) {
    return DecorationAddon(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      price: (json['price'] is num)
          ? (json['price'] as num).toDouble()
          : double.tryParse(json['price']?.toString() ?? '0') ?? 0.0,
      description: json['description'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'description': description,
      'image_url': imageUrl,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DecorationAddon &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
