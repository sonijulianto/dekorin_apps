import 'decoration_model.dart';

class PackageModelItem {
  const PackageModelItem({
    required this.id,
    required this.packageId,
    required this.decorationModelId,
    required this.additionalPrice,
    this.sortOrder = 0,
    this.decorationModel,
  });

  final String id;
  final String packageId;
  final String decorationModelId;
  final double additionalPrice;
  final int sortOrder;
  final DecorationModel? decorationModel;

  factory PackageModelItem.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    DecorationModel? model;
    if (json['decoration_model'] != null && json['decoration_model'] is Map<String, dynamic>) {
      model = DecorationModel.fromJson(json['decoration_model'] as Map<String, dynamic>);
    }

    return PackageModelItem(
      id: json['id'] as String? ?? '',
      packageId: json['package_id'] as String? ?? '',
      decorationModelId: json['decoration_model_id'] as String? ?? json['model_id'] as String? ?? '',
      additionalPrice: parseDouble(json['additional_price']),
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      decorationModel: model,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'package_id': packageId,
      'decoration_model_id': decorationModelId,
      'additional_price': additionalPrice,
      'sort_order': sortOrder,
      if (decorationModel != null) 'decoration_model': decorationModel!.toJson(),
    };
  }

  PackageModelItem copyWith({
    String? id,
    String? packageId,
    String? decorationModelId,
    double? additionalPrice,
    int? sortOrder,
    DecorationModel? decorationModel,
  }) {
    return PackageModelItem(
      id: id ?? this.id,
      packageId: packageId ?? this.packageId,
      decorationModelId: decorationModelId ?? this.decorationModelId,
      additionalPrice: additionalPrice ?? this.additionalPrice,
      sortOrder: sortOrder ?? this.sortOrder,
      decorationModel: decorationModel ?? this.decorationModel,
    );
  }
}

class DecorationPackage {
  const DecorationPackage({
    required this.id,
    this.brandId = '',
    this.brandName = '',
    required this.name,
    required this.description,
    required this.basePrice,
    this.imageUrl = '',
    this.sortOrder = 0,
    this.packageModels = const [],
  });

  final String id;
  final String brandId;
  final String brandName;
  final String name;
  final String description;
  final double basePrice;
  final String imageUrl;
  final int sortOrder;
  final List<PackageModelItem> packageModels;

  factory DecorationPackage.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    List<PackageModelItem> models = [];
    if (json['package_models'] != null && json['package_models'] is List) {
      models = (json['package_models'] as List)
          .map((item) => PackageModelItem.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return DecorationPackage(
      id: json['id'] as String? ?? '',
      brandId: json['brand_id'] as String? ?? '',
      brandName: json['brand_name'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      imageUrl: json['image_url'] as String? ?? '',
      basePrice: parseDouble(json['base_price']),
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      packageModels: models,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'brand_id': brandId,
      'brand_name': brandName,
      'name': name,
      'description': description,
      'image_url': imageUrl,
      'base_price': basePrice,
      'sort_order': sortOrder,
      'package_models': packageModels.map((m) => m.toJson()).toList(),
    };
  }

  DecorationPackage copyWith({
    String? id,
    String? brandId,
    String? brandName,
    String? name,
    String? description,
    double? basePrice,
    String? imageUrl,
    int? sortOrder,
    List<PackageModelItem>? packageModels,
  }) {
    return DecorationPackage(
      id: id ?? this.id,
      brandId: brandId ?? this.brandId,
      brandName: brandName ?? this.brandName,
      name: name ?? this.name,
      description: description ?? this.description,
      basePrice: basePrice ?? this.basePrice,
      imageUrl: imageUrl ?? this.imageUrl,
      sortOrder: sortOrder ?? this.sortOrder,
      packageModels: packageModels ?? this.packageModels,
    );
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
