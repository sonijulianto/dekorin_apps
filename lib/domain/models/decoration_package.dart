class DecorationPackage {
  const DecorationPackage({
    required this.id,
    required this.name,
    required this.description,
    required this.basePrice,
  });

  final String id;
  final String name;
  final String description;
  final double basePrice;

  factory DecorationPackage.fromJson(Map<String, dynamic> json) {
    return DecorationPackage(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      basePrice: (json['base_price'] is num)
          ? (json['base_price'] as num).toDouble()
          : double.tryParse(json['base_price']?.toString() ?? '0') ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'base_price': basePrice,
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
