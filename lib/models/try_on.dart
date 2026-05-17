import 'package:cinduhrella/models/body_measurements.dart';
import 'package:cinduhrella/models/cloth.dart';
import 'package:cinduhrella/models/style_brief.dart';

class TryOnRequest {
  final String userId;
  final String? baseImageUrl;
  final BodyMeasurements bodyMeasurements;
  final SilhouetteProfile silhouette;
  final List<Cloth> clothes;
  final List<OccasionTag> occasionTags;

  const TryOnRequest({
    required this.userId,
    required this.baseImageUrl,
    required this.bodyMeasurements,
    required this.silhouette,
    required this.clothes,
    required this.occasionTags,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'baseImageUrl': baseImageUrl,
      'bodyMeasurements': bodyMeasurements.toJson(),
      'silhouette': silhouette.name,
      'clothes': clothes.map((cloth) => cloth.toJson()).toList(),
      'occasionTags': occasionTags.map((tag) => tag.name).toList(),
    };
  }
}

class TryOnLayer {
  final String label;
  final String description;

  const TryOnLayer({
    required this.label,
    required this.description,
  });

  factory TryOnLayer.fromJson(Map<String, dynamic> json) {
    return TryOnLayer(
      label: json['label'] ?? '',
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'description': description,
    };
  }
}

class TryOnPreview {
  final String renderer;
  final String summary;
  final String renderPrompt;
  final String? assetUrl;
  final bool readyForRemoteRenderer;
  final List<TryOnLayer> layers;

  const TryOnPreview({
    required this.renderer,
    required this.summary,
    required this.renderPrompt,
    required this.assetUrl,
    required this.readyForRemoteRenderer,
    required this.layers,
  });

  factory TryOnPreview.fromJson(Map<String, dynamic> json) {
    return TryOnPreview(
      renderer: json['renderer'] ?? 'remote-renderer',
      summary: json['summary'] ?? '',
      renderPrompt: json['renderPrompt'] ?? '',
      assetUrl: json['assetUrl'],
      readyForRemoteRenderer: json['readyForRemoteRenderer'] ?? false,
      layers: (json['layers'] as List<dynamic>? ?? [])
          .map((item) => TryOnLayer.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'renderer': renderer,
      'summary': summary,
      'renderPrompt': renderPrompt,
      'assetUrl': assetUrl,
      'readyForRemoteRenderer': readyForRemoteRenderer,
      'layers': layers.map((layer) => layer.toJson()).toList(),
    };
  }
}
