import 'package:cinduhrella/models/cloth.dart';

enum DraftItemStatus { draftDetected, confirmedOwned, dismissed }

enum DraftItemSource {
  bulkPhoto,
  ownerPhotoLibrary,
  retailerPurchase,
  manual,
  recommendationFeedback
}

class DraftCloth {
  final String draftId;
  final String uid;
  final String imageUrl;
  final String? brand;
  final String? size;
  final String? description;
  final String? type;
  final String? color;
  final double confidence;
  final DraftItemStatus status;
  final DraftItemSource source;
  final String? captureSessionId;
  final bool needsReview;
  final DateTime createdAt;
  final double ownerMatchConfidence;
  final String importContext;

  const DraftCloth({
    required this.draftId,
    required this.uid,
    required this.imageUrl,
    required this.confidence,
    required this.status,
    required this.source,
    required this.needsReview,
    required this.createdAt,
    this.brand,
    this.size,
    this.description,
    this.type,
    this.color,
    this.captureSessionId,
    this.ownerMatchConfidence = 0,
    this.importContext = '',
  });

  factory DraftCloth.fromJson(Map<String, dynamic> json) {
    return DraftCloth(
      draftId: json['draftId'] ?? '',
      uid: json['uid'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      brand: json['brand'],
      size: json['size'],
      description: json['description'],
      type: json['type'],
      color: json['color'],
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      status: DraftItemStatus.values.firstWhere(
        (value) => value.name == json['status'],
        orElse: () => DraftItemStatus.draftDetected,
      ),
      source: DraftItemSource.values.firstWhere(
        (value) => value.name == json['source'],
        orElse: () => DraftItemSource.bulkPhoto,
      ),
      captureSessionId: json['captureSessionId'],
      needsReview: json['needsReview'] ?? true,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      ownerMatchConfidence:
          (json['ownerMatchConfidence'] as num?)?.toDouble() ?? 0,
      importContext: json['importContext'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'draftId': draftId,
      'uid': uid,
      'imageUrl': imageUrl,
      'brand': brand,
      'size': size,
      'description': description,
      'type': type,
      'color': color,
      'confidence': confidence,
      'status': status.name,
      'source': source.name,
      'captureSessionId': captureSessionId,
      'needsReview': needsReview,
      'createdAt': createdAt.toIso8601String(),
      'ownerMatchConfidence': ownerMatchConfidence,
      'importContext': importContext,
    };
  }

  DraftCloth copyWith({
    String? brand,
    String? size,
    String? description,
    String? type,
    String? color,
    double? confidence,
    DraftItemStatus? status,
    bool? needsReview,
    double? ownerMatchConfidence,
    String? importContext,
  }) {
    return DraftCloth(
      draftId: draftId,
      uid: uid,
      imageUrl: imageUrl,
      brand: brand ?? this.brand,
      size: size ?? this.size,
      description: description ?? this.description,
      type: type ?? this.type,
      color: color ?? this.color,
      confidence: confidence ?? this.confidence,
      status: status ?? this.status,
      source: source,
      captureSessionId: captureSessionId,
      needsReview: needsReview ?? this.needsReview,
      createdAt: createdAt,
      ownerMatchConfidence: ownerMatchConfidence ?? this.ownerMatchConfidence,
      importContext: importContext ?? this.importContext,
    );
  }

  Cloth toCloth() {
    return Cloth(
      clothId: draftId,
      storageId: null,
      uid: uid,
      imageUrl: imageUrl,
      brand: brand,
      size: size,
      description: description,
      type: type,
      color: color,
    );
  }
}
