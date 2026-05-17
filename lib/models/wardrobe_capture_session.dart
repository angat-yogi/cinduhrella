class WardrobeCaptureSession {
  final String sessionId;
  final String uid;
  final List<String> imageUrls;
  final int detectedCount;
  final int confirmedCount;
  final DateTime createdAt;

  const WardrobeCaptureSession({
    required this.sessionId,
    required this.uid,
    required this.imageUrls,
    required this.detectedCount,
    required this.confirmedCount,
    required this.createdAt,
  });

  factory WardrobeCaptureSession.fromJson(Map<String, dynamic> json) {
    return WardrobeCaptureSession(
      sessionId: json['sessionId'] ?? '',
      uid: json['uid'] ?? '',
      imageUrls: List<String>.from(json['imageUrls'] ?? []),
      detectedCount: json['detectedCount'] ?? 0,
      confirmedCount: json['confirmedCount'] ?? 0,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'uid': uid,
      'imageUrls': imageUrls,
      'detectedCount': detectedCount,
      'confirmedCount': confirmedCount,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
