class PhotoImportPreferences {
  final bool consentGranted;
  final bool ownerOnlyImportEnabled;
  final List<String> ownerReferenceImageUrls;
  final DateTime? consentedAt;
  final String ownerIdentityHint;
  final String sourceCollectionId;
  final String sourceCollectionName;
  final bool collectionAutoSyncEnabled;
  final bool autoCurateIntoAlbumEnabled;
  final List<String> processedSourceAssetIds;
  final DateTime? lastCollectionSyncAt;
  final List<String> curatedSourceAssetIds;
  final DateTime? lastAutoCurateAt;

  const PhotoImportPreferences({
    this.consentGranted = false,
    this.ownerOnlyImportEnabled = true,
    this.ownerReferenceImageUrls = const [],
    this.consentedAt,
    this.ownerIdentityHint = '',
    this.sourceCollectionId = '',
    this.sourceCollectionName = '',
    this.collectionAutoSyncEnabled = false,
    this.autoCurateIntoAlbumEnabled = false,
    this.processedSourceAssetIds = const [],
    this.lastCollectionSyncAt,
    this.curatedSourceAssetIds = const [],
    this.lastAutoCurateAt,
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
      autoCurateIntoAlbumEnabled: json['autoCurateIntoAlbumEnabled'] ?? false,
      processedSourceAssetIds:
          List<String>.from(json['processedSourceAssetIds'] ?? const []),
      lastCollectionSyncAt:
          DateTime.tryParse(json['lastCollectionSyncAt'] ?? ''),
      curatedSourceAssetIds:
          List<String>.from(json['curatedSourceAssetIds'] ?? const []),
      lastAutoCurateAt: DateTime.tryParse(json['lastAutoCurateAt'] ?? ''),
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
      'autoCurateIntoAlbumEnabled': autoCurateIntoAlbumEnabled,
      'processedSourceAssetIds': processedSourceAssetIds,
      'lastCollectionSyncAt': lastCollectionSyncAt?.toIso8601String(),
      'curatedSourceAssetIds': curatedSourceAssetIds,
      'lastAutoCurateAt': lastAutoCurateAt?.toIso8601String(),
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
    bool? autoCurateIntoAlbumEnabled,
    List<String>? processedSourceAssetIds,
    DateTime? lastCollectionSyncAt,
    List<String>? curatedSourceAssetIds,
    DateTime? lastAutoCurateAt,
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
      autoCurateIntoAlbumEnabled:
          autoCurateIntoAlbumEnabled ?? this.autoCurateIntoAlbumEnabled,
      processedSourceAssetIds:
          processedSourceAssetIds ?? this.processedSourceAssetIds,
      lastCollectionSyncAt: lastCollectionSyncAt ?? this.lastCollectionSyncAt,
      curatedSourceAssetIds:
          curatedSourceAssetIds ?? this.curatedSourceAssetIds,
      lastAutoCurateAt: lastAutoCurateAt ?? this.lastAutoCurateAt,
    );
  }
}
