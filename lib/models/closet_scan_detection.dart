import 'dart:convert';
import 'dart:typed_data';

class ClosetScanDetection {
  final String tempId;
  final String rawLabel;
  final String normalizedCategory;
  final String displayLabel;
  final List<String> colors;
  final double confidence;
  final Map<String, dynamic> bbox;
  final Uint8List cropBytes;
  final bool approved;

  const ClosetScanDetection({
    required this.tempId,
    required this.rawLabel,
    required this.normalizedCategory,
    required this.displayLabel,
    required this.colors,
    required this.confidence,
    required this.bbox,
    required this.cropBytes,
    this.approved = true,
  });

  factory ClosetScanDetection.fromJson(
    Map<String, dynamic> json, {
    required String tempId,
  }) {
    return ClosetScanDetection(
      tempId: tempId,
      rawLabel: json['rawLabel'] ?? '',
      normalizedCategory: json['normalizedCategory'] ?? '',
      displayLabel: json['displayLabel'] ?? '',
      colors: List<String>.from(json['colors'] ?? const []),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      bbox: Map<String, dynamic>.from(json['bbox'] ?? const {}),
      cropBytes: base64Decode(json['cropBase64'] ?? ''),
    );
  }

  ClosetScanDetection copyWith({
    bool? approved,
  }) {
    return ClosetScanDetection(
      tempId: tempId,
      rawLabel: rawLabel,
      normalizedCategory: normalizedCategory,
      displayLabel: displayLabel,
      colors: colors,
      confidence: confidence,
      bbox: bbox,
      cropBytes: cropBytes,
      approved: approved ?? this.approved,
    );
  }

  String get duplicateKey {
    final colorKey = colors.take(2).join('-');
    return '${normalizedCategory.toLowerCase()}|${displayLabel.toLowerCase()}|$colorKey';
  }
}
