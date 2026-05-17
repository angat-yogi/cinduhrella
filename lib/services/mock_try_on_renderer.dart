import 'package:cinduhrella/models/try_on.dart';
import 'package:cinduhrella/services/try_on_renderer.dart';

class MockTryOnRenderer implements TryOnRenderer {
  @override
  Future<TryOnPreview> render(TryOnRequest request) async {
    final garmentSummary = request.clothes
        .map((cloth) => '${cloth.color ?? 'neutral'} ${cloth.type ?? 'piece'}')
        .join(', ');
    final occasionSummary =
        request.occasionTags.map((tag) => tag.name).join(', ');

    return TryOnPreview(
      renderer: 'mock-static-renderer',
      summary:
          'Prepared a static try-on stack for $garmentSummary on a ${request.silhouette.name} body form.',
      renderPrompt:
          'Render a static outfit preview using body measurements. Silhouette: ${request.silhouette.name}. '
          'Occasions: $occasionSummary. Garments: $garmentSummary.',
      assetUrl: null,
      readyForRemoteRenderer: request.baseImageUrl != null &&
          request.bodyMeasurements.hasEnoughDataForPreview,
      layers: request.clothes
          .map(
            (cloth) => TryOnLayer(
              label: cloth.type ?? 'Garment',
              description:
                  '${cloth.brand ?? 'Unbranded'} ${cloth.color ?? 'neutral'} ${cloth.description ?? 'piece'}',
            ),
          )
          .toList(),
    );
  }
}
