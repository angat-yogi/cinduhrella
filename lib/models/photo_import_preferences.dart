class PhotoImportPreferences {
  final bool consentGranted;
  final bool ownerOnlyImportEnabled;
  final List<String> ownerReferenceImageUrls;
  final DateTime? consentedAt;
  final String ownerIdentityHint;

  const PhotoImportPreferences({
    this.consentGranted = false,
    this.ownerOnlyImportEnabled = true,
    this.ownerReferenceImageUrls = const [],
    this.consentedAt,
    this.ownerIdentityHint = '',
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
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'consentGranted': consentGranted,
      'ownerOnlyImportEnabled': ownerOnlyImportEnabled,
      'ownerReferenceImageUrls': ownerReferenceImageUrls,
      'consentedAt': consentedAt?.toIso8601String(),
      'ownerIdentityHint': ownerIdentityHint,
    };
  }

  PhotoImportPreferences copyWith({
    bool? consentGranted,
    bool? ownerOnlyImportEnabled,
    List<String>? ownerReferenceImageUrls,
    DateTime? consentedAt,
    String? ownerIdentityHint,
  }) {
    return PhotoImportPreferences(
      consentGranted: consentGranted ?? this.consentGranted,
      ownerOnlyImportEnabled:
          ownerOnlyImportEnabled ?? this.ownerOnlyImportEnabled,
      ownerReferenceImageUrls:
          ownerReferenceImageUrls ?? this.ownerReferenceImageUrls,
      consentedAt: consentedAt ?? this.consentedAt,
      ownerIdentityHint: ownerIdentityHint ?? this.ownerIdentityHint,
    );
  }
}
