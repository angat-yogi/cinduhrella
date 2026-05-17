class GarmentAsset {
  final String garmentAssetId;
  final String uid;
  final String imageUrl;
  final String category;
  final String? maskUrl;
  final String? brand;
  final String? color;
  final String? size;
  final String? description;
  final String? sourceClothId;
  final DateTime createdAt;

  const GarmentAsset({
    required this.garmentAssetId,
    required this.uid,
    required this.imageUrl,
    required this.category,
    required this.createdAt,
    this.maskUrl,
    this.brand,
    this.color,
    this.size,
    this.description,
    this.sourceClothId,
  });

  factory GarmentAsset.fromJson(Map<String, dynamic> json) {
    return GarmentAsset(
      garmentAssetId: json['garmentAssetId'] ?? '',
      uid: json['uid'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      category: json['category'] ?? 'top',
      maskUrl: json['maskUrl'],
      brand: json['brand'],
      color: json['color'],
      size: json['size'],
      description: json['description'],
      sourceClothId: json['sourceClothId'],
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'garmentAssetId': garmentAssetId,
      'uid': uid,
      'imageUrl': imageUrl,
      'category': category,
      'maskUrl': maskUrl,
      'brand': brand,
      'color': color,
      'size': size,
      'description': description,
      'sourceClothId': sourceClothId,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
