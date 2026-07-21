import 'package:cached_network_image/cached_network_image.dart';
import 'package:cinduhrella/models/cloth.dart';
import 'package:cinduhrella/models/styled_outfit.dart';
import 'package:flutter/material.dart';

class StyledOutfitPreview extends StatelessWidget {
  final StyledOutfit outfit;
  final bool showTitle;
  final EdgeInsets padding;

  const StyledOutfitPreview({
    required this.outfit,
    this.showTitle = true,
    this.padding = const EdgeInsets.all(16),
    super.key,
  });

  static const Map<String, double> _baseWidths = {
    'top': 150,
    'bottom': 156,
    'accessory': 92,
  };

  static const Map<String, double> _baseHeights = {
    'top': 150,
    'bottom': 176,
    'accessory': 92,
  };

  @override
  Widget build(BuildContext context) {
    final placements = _normalizedPlacements(outfit);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFFFCFA),
            Color(0xFFF4F2FF),
          ],
          stops: [0.1, 1],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showTitle)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    outfit.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF201A2B),
                    ),
                  ),
                ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final sorted = [...placements]
                      ..sort((a, b) => a.zIndex.compareTo(b.zIndex));
                    return Stack(
                      children: [
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Colors.black.withValues(alpha: 0.04),
                              ),
                              gradient: RadialGradient(
                                colors: [
                                  Colors.white.withValues(alpha: 0.94),
                                  const Color(0xFFF0EEFF),
                                ],
                                center: const Alignment(0, -0.2),
                                radius: 1.0,
                              ),
                            ),
                          ),
                        ),
                        ...sorted.map(
                          (placement) => _buildPlacement(
                            placement,
                            constraints.maxWidth,
                            constraints.maxHeight,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlacement(
    StyledOutfitPlacement placement,
    double boardWidth,
    double boardHeight,
  ) {
    final category = placement.category.toLowerCase();
    final contentWidth = (_baseWidths[category] ?? 92) * placement.scale;
    final contentHeight = (_baseHeights[category] ?? 92) * placement.scale;
    final rotatesBounds = placement.quarterTurns.isOdd;
    final width = rotatesBounds ? contentHeight : contentWidth;
    final height = rotatesBounds ? contentWidth : contentHeight;
    final dx = (placement.normalizedDx * boardWidth) - (width / 2);
    final dy = (placement.normalizedDy * boardHeight) - (height / 2);
    final safeLeft =
        dx.clamp(0.0, boardWidth > width ? boardWidth - width : 0.0).toDouble();
    final safeTop = dy
        .clamp(0.0, boardHeight > height ? boardHeight - height : 0.0)
        .toDouble();

    return Positioned(
      left: safeLeft,
      top: safeTop,
      child: SizedBox(
        width: width,
        height: height,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: RotatedBox(
            quarterTurns: placement.quarterTurns,
            child: CachedNetworkImage(
              imageUrl: placement.cloth.imageUrl ?? '',
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.black12,
                child: const Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.black.withValues(alpha: 0.03),
                alignment: Alignment.center,
                child: const Icon(Icons.broken_image_outlined),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<StyledOutfitPlacement> _normalizedPlacements(StyledOutfit outfit) {
    if (outfit.placements.isNotEmpty) {
      return outfit.placements;
    }

    int topCount = 0;
    int bottomCount = 0;
    int accessoryCount = 0;
    final placements = <StyledOutfitPlacement>[];

    for (var index = 0; index < outfit.clothes.length; index++) {
      final cloth = outfit.clothes[index];
      final category = _categoryForCloth(cloth);
      final currentCount = switch (category) {
        'top' => topCount++,
        'bottom' => bottomCount++,
        _ => accessoryCount++,
      };

      placements.add(
        StyledOutfitPlacement(
          placementId: cloth.clothId ?? 'placement_$index',
          cloth: cloth,
          category: category,
          normalizedDx: _defaultPositionFor(category, currentCount).dx,
          normalizedDy: _defaultPositionFor(category, currentCount).dy,
          scale: _defaultScaleFor(category),
          zIndex: index,
        ),
      );
    }

    return placements;
  }

  String _categoryForCloth(Cloth cloth) {
    final type = (cloth.type ?? '').toLowerCase();
    if (type == 'top wear') {
      return 'top';
    }
    if (type == 'bottom wear') {
      return 'bottom';
    }
    return 'accessory';
  }

  Offset _defaultPositionFor(String category, int categoryCount) {
    switch (category) {
      case 'top':
        return categoryCount == 0
            ? const Offset(0.50, 0.28)
            : const Offset(0.50, 0.18);
      case 'bottom':
        return categoryCount == 0
            ? const Offset(0.50, 0.58)
            : const Offset(0.50, 0.70);
      default:
        return switch (categoryCount) {
          0 => const Offset(0.33, 0.80),
          1 => const Offset(0.67, 0.80),
          _ => const Offset(0.50, 0.72),
        };
    }
  }

  double _defaultScaleFor(String category) {
    switch (category) {
      case 'top':
        return 1.0;
      case 'bottom':
        return 1.08;
      default:
        return 0.72;
    }
  }
}
