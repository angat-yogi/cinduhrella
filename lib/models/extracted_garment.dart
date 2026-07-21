import 'dart:convert';
import 'dart:typed_data';

class ExtractedGarment {
  final String parserLabel;
  final String type;
  final String displayLabel;
  final List<String> colors;
  final double confidence;
  final Map<String, dynamic> bbox;
  final Uint8List cropBytes;

  const ExtractedGarment({
    required this.parserLabel,
    required this.type,
    required this.displayLabel,
    required this.colors,
    required this.confidence,
    required this.bbox,
    required this.cropBytes,
  });

  factory ExtractedGarment.fromJson(Map<String, dynamic> json) {
    return ExtractedGarment(
      parserLabel: (json['parserLabel'] ?? '').toString(),
      type: (json['type'] ?? '').toString(),
      displayLabel: (json['displayLabel'] ?? '').toString(),
      colors: List<String>.from(json['colors'] ?? const []),
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0,
      bbox: Map<String, dynamic>.from(json['bbox'] ?? const {}),
      cropBytes: base64Decode((json['cropBase64'] ?? '').toString()),
    );
  }
}
