import 'package:cinduhrella/models/body_measurements.dart';

class BodyProfile {
  final String bodyProfileId;
  final String uid;
  final String frontImageUrl;
  final String? sideImageUrl;
  final BodyMeasurements measurements;
  final bool isPrimary;
  final DateTime createdAt;

  const BodyProfile({
    required this.bodyProfileId,
    required this.uid,
    required this.frontImageUrl,
    required this.measurements,
    required this.isPrimary,
    required this.createdAt,
    this.sideImageUrl,
  });

  factory BodyProfile.fromJson(Map<String, dynamic> json) {
    return BodyProfile(
      bodyProfileId: json['bodyProfileId'] ?? '',
      uid: json['uid'] ?? '',
      frontImageUrl: json['frontImageUrl'] ?? '',
      sideImageUrl: json['sideImageUrl'],
      measurements: BodyMeasurements.fromJson(
        json['measurements'] as Map<String, dynamic>?,
      ),
      isPrimary: json['isPrimary'] ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bodyProfileId': bodyProfileId,
      'uid': uid,
      'frontImageUrl': frontImageUrl,
      'sideImageUrl': sideImageUrl,
      'measurements': measurements.toJson(),
      'isPrimary': isPrimary,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
