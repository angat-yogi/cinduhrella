class PhotoImportPreferences {
  final bool consentGranted;
  final bool ownerOnlyImportEnabled;
  final List<String> ownerReferenceImageUrls;
  final DateTime? consentedAt;
  final String ownerIdentityHint;
  final String sourceCollectionId;
  final String sourceCollectionName;
  final bool collectionAutoSyncEnabled;
  final List<String> processedSourceAssetIds;
  final DateTime? lastCollectionSyncAt;

  const PhotoImportPreferences({
    this.consentGranted = false,
    this.ownerOnlyImportEnabled = true,
    this.ownerReferenceImageUrls = const [],
    this.consentedAt,
    this.ownerIdentityHint = '',
    this.sourceCollectionId = '',
    this.sourceCollectionName = '',
    this.collectionAutoSyncEnabled = false,
    this.processedSourceAssetIds = const [],
    this.lastCollectionSyncAt,
  });

  factory PhotoImportPreferences.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const PhotoImportPreferences();
    }
    return PhotoImportPreferences(
      consentGranted: json['consentGranted'] ?? false,
      ownerOnlyImportEnabled: json['ownerOnlyImportEnabled'] ?? true,
      ownerReferenceImageUrls:
          List<String>.from(json['ownerReferenceImageUrls'] ?? const []),
      consentedAt: DateTime.tryParse(json['consentedAt'] ?? ''),
      ownerIdentityHint: json['ownerIdentityHint'] ?? '',
      sourceCollectionId: json['sourceCollectionId'] ?? '',
      sourceCollectionName: json['sourceCollectionName'] ?? '',
      collectionAutoSyncEnabled: json['collectionAutoSyncEnabled'] ?? false,
      processedSourceAssetIds:
          List<String>.from(json['processedSourceAssetIds'] ?? const []),
      lastCollectionSyncAt:
          DateTime.tryParse(json['lastCollectionSyncAt'] ?? ''),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'consentGranted': consentGranted,
      'ownerOnlyImportEnabled': ownerOnlyImportEnabled,
      'ownerReferenceImageUrls': ownerReferenceImageUrls,
      'consentedAt': consentedAt?.toIso8601String(),
      'ownerIdentityHint': ownerIdentityHint,
      'sourceCollectionId': sourceCollectionId,
      'sourceCollectionName': sourceCollectionName,
      'collectionAutoSyncEnabled': collectionAutoSyncEnabled,
      'processedSourceAssetIds': processedSourceAssetIds,
      'lastCollectionSyncAt': lastCollectionSyncAt?.toIso8601String(),
    };
  }

  PhotoImportPreferences copyWith({
    bool? consentGranted,
    bool? ownerOnlyImportEnabled,
    List<String>? ownerReferenceImageUrls,
    DateTime? consentedAt,
    String? ownerIdentityHint,
    String? sourceCollectionId,
    String? sourceCollectionName,
    bool? collectionAutoSyncEnabled,
    List<String>? processedSourceAssetIds,
    DateTime? lastCollectionSyncAt,
  }) {
    return PhotoImportPreferences(
      consentGranted: consentGranted ?? this.consentGranted,
      ownerOnlyImportEnabled:
          ownerOnlyImportEnabled ?? this.ownerOnlyImportEnabled,
      ownerReferenceImageUrls:
          ownerReferenceImageUrls ?? this.ownerReferenceImageUrls,
      consentedAt: consentedAt ?? this.consentedAt,
      ownerIdentityHint: ownerIdentityHint ?? this.ownerIdentityHint,
      sourceCollectionId: sourceCollectionId ?? this.sourceCollectionId,
      sourceCollectionName: sourceCollectionName ?? this.sourceCollectionName,
      collectionAutoSyncEnabled:
          collectionAutoSyncEnabled ?? this.collectionAutoSyncEnabled,
      processedSourceAssetIds:
          processedSourceAssetIds ?? this.processedSourceAssetIds,
      lastCollectionSyncAt: lastCollectionSyncAt ?? this.lastCollectionSyncAt,
    );
  }
}
