import 'package:cinduhrella/models/cloth.dart';
import 'package:cinduhrella/models/outfit_recommendation.dart';
import 'package:cinduhrella/models/style_brief.dart';
import 'package:cinduhrella/services/database_service.dart';
import 'package:get_it/get_it.dart';

class WardrobeEngineService {
  WardrobeEngineService() {
    _databaseService = GetIt.instance.get<DatabaseService>();
  }

  late final DatabaseService _databaseService;

  Future<List<OutfitRecommendation>> buildRecommendations(
    String userId,
    StyleBrief brief,
  ) async {
    final categorizedItems = await _databaseService.fetchUserItems(userId);
    final draftItems = await _databaseService.fetchDraftItemsForPlanner(userId);
    final mergedItems = _mergeCategorizedItems(categorizedItems, draftItems);
    final tops = _toClothes(mergedItems['top wear']);
    final bottoms = _toClothes(mergedItems['bottom wear']);
    final accessories = _toClothes(mergedItems['accessories']);

    if (tops.isEmpty || bottoms.isEmpty) {
      return [
        OutfitRecommendation(
          title: 'Inventory gap found',
          reason:
              'A complete outfit needs at least one top and one bottom before the engine can style against occasion, climate, dress code, and silhouette.',
          clothes: const [],
          score: 0,
          breakdown: const RecommendationBreakdown(
            occasionScore: 0,
            climateScore: 0,
            dressCodeScore: 0,
            silhouetteScore: 0,
            reuseScore: 0,
          ),
          stylingNotes: const [
            'Fill the missing basic first.',
            'The buy recommendation is limited to the smallest gap needed to unlock more looks.',
          ],
          matchedOccasions: brief.occasionTags,
          purchaseSuggestion: _buildPurchaseSuggestion(
            itemType: tops.isEmpty ? 'Top Wear' : 'Bottom Wear',
            existingCloset: tops.isEmpty ? bottoms : tops,
            brief: brief,
          ),
        ),
      ];
    }

    final recommendations = <OutfitRecommendation>[];
    final candidateTops = [...tops]..sort(
        (a, b) => _scoreGarment(b, brief).compareTo(_scoreGarment(a, brief)));
    final candidateBottoms = [...bottoms]..sort(
        (a, b) => _scoreGarment(b, brief).compareTo(_scoreGarment(a, brief)));
    final candidateAccessories = [...accessories]..sort(
        (a, b) => _scoreGarment(b, brief).compareTo(_scoreGarment(a, brief)));

    for (final top in candidateTops.take(4)) {
      for (final bottom in candidateBottoms.take(4)) {
        final outfit = <Cloth>[top, bottom];
        final occasionScore = _scoreOccasion(outfit, brief);
        final climateScore = _scoreClimate(outfit, brief);
        final dressCodeScore = _scoreDressCode(outfit, brief);
        final silhouetteScore = _scoreSilhouette(outfit, brief);
        final reuseScore = _scoreReuse(outfit, candidateAccessories, brief);

        if (candidateAccessories.isNotEmpty && dressCodeScore >= 2.5) {
          outfit.add(candidateAccessories.first);
        }

        final score = occasionScore +
            climateScore +
            dressCodeScore +
            silhouetteScore +
            reuseScore;

        recommendations.add(
          OutfitRecommendation(
            title: _buildTitle(brief, top, bottom),
            reason: _buildReason(
              brief: brief,
              score: score,
              occasionScore: occasionScore,
              climateScore: climateScore,
              dressCodeScore: dressCodeScore,
            ),
            clothes: outfit,
            score: score,
            breakdown: RecommendationBreakdown(
              occasionScore: occasionScore,
              climateScore: climateScore,
              dressCodeScore: dressCodeScore,
              silhouetteScore: silhouetteScore,
              reuseScore: reuseScore,
            ),
            stylingNotes: _buildStylingNotes(outfit, brief),
            matchedOccasions: _matchOccasions(outfit, brief),
            purchaseSuggestion: _needsPurchase(score, outfit, brief)
                ? _buildPurchaseSuggestion(
                    itemType: _suggestMissingCategory(outfit, brief),
                    existingCloset: outfit,
                    brief: brief,
                  )
                : null,
          ),
        );
      }
    }

    recommendations.sort((a, b) => b.score.compareTo(a.score));
    return recommendations.take(4).toList();
  }

  Map<String, List<Map<String, dynamic>>> _mergeCategorizedItems(
    Map<String, List<Map<String, dynamic>>> primary,
    Map<String, List<Map<String, dynamic>>> secondary,
  ) {
    return {
      'top wear': [
        ...(primary['top wear'] ?? []),
        ...(secondary['top wear'] ?? []),
      ],
      'bottom wear': [
        ...(primary['bottom wear'] ?? []),
        ...(secondary['bottom wear'] ?? []),
      ],
      'accessories': [
        ...(primary['accessories'] ?? []),
        ...(secondary['accessories'] ?? []),
      ],
    };
  }

  List<Cloth> _toClothes(List<Map<String, dynamic>>? items) {
    if (items == null) {
      return [];
    }
    return items
        .map(
          (item) => Cloth(
            clothId: item['id'] ?? item['clothId'],
            storageId: item['storageId'],
            uid: item['uid'],
            imageUrl: item['imageUrl'] ?? '',
            brand: item['brand'],
            size: item['size'],
            description: item['description'],
            type: item['type'],
            color: item['color'],
          ),
        )
        .toList();
  }

  double _scoreGarment(Cloth cloth, StyleBrief brief) {
    return _scoreOccasion([cloth], brief) +
        _scoreClimate([cloth], brief) +
        _scoreDressCode([cloth], brief) +
        _scoreSilhouette([cloth], brief);
  }

  double _scoreOccasion(List<Cloth> clothes, StyleBrief brief) {
    double score = 0;
    final tags = _deriveOccasions(clothes);
    for (final tag in brief.occasionTags) {
      if (tags.contains(tag)) {
        score += 2.5;
      }
    }
    if (brief.occasionTags.isEmpty) {
      score += 1.5;
    }
    return score;
  }

  double _scoreClimate(List<Cloth> clothes, StyleBrief brief) {
    final signals = clothes.map(_deriveClimate).toList();
    final matches = signals.where((signal) => signal == brief.climate).length;
    if (matches == 0) {
      return 0.5;
    }
    return matches * 1.5;
  }

  double _scoreDressCode(List<Cloth> clothes, StyleBrief brief) {
    double score = 0;
    for (final cloth in clothes) {
      final code = _deriveDressCode(cloth);
      if (code == brief.dressCode) {
        score += 2;
      } else if (_isAdjacentDressCode(code, brief.dressCode)) {
        score += 1;
      }
    }
    return score;
  }

  double _scoreSilhouette(List<Cloth> clothes, StyleBrief brief) {
    double score = 0;
    for (final cloth in clothes) {
      final silhouette = _deriveSilhouette(cloth);
      if (silhouette == brief.silhouette) {
        score += 2;
      } else if (_compatibleSilhouettes(silhouette, brief.silhouette)) {
        score += 1;
      }
    }
    return score;
  }

  double _scoreReuse(
    List<Cloth> clothes,
    List<Cloth> accessories,
    StyleBrief brief,
  ) {
    final colors = clothes
        .map((cloth) => (cloth.color ?? '').toLowerCase())
        .where((color) => color.isNotEmpty)
        .toSet();
    double score = colors.length <= 2 ? 2 : 1;
    if (brief.focus == PlanningFocus.trip && brief.tripDays > 3) {
      score += 1.5;
    }
    if (accessories.isNotEmpty) {
      score += 0.5;
    }
    return score;
  }

  List<OccasionTag> _deriveOccasions(List<Cloth> clothes) {
    final matches = <OccasionTag>{};
    for (final cloth in clothes) {
      final text =
          '${cloth.type ?? ''} ${cloth.description ?? ''} ${cloth.brand ?? ''}'
              .toLowerCase();
      if (text.contains('formal') ||
          text.contains('blazer') ||
          text.contains('suit')) {
        matches.add(OccasionTag.work);
        matches.add(OccasionTag.dinner);
      }
      if (text.contains('casual') ||
          text.contains('sneaker') ||
          text.contains('jeans')) {
        matches.add(OccasionTag.casual);
      }
      if (text.contains('party') || text.contains('dress')) {
        matches.add(OccasionTag.party);
      }
      if (text.contains('vacation') || text.contains('light')) {
        matches.add(OccasionTag.vacation);
      }
      if (text.contains('hoodie') || text.contains('sweat')) {
        matches.add(OccasionTag.lounge);
      }
    }
    if (matches.isEmpty) {
      matches.add(OccasionTag.casual);
    }
    return matches.toList();
  }

  ClimateBand _deriveClimate(Cloth cloth) {
    final text = '${cloth.type ?? ''} ${cloth.description ?? ''}'.toLowerCase();
    if (text.contains('coat') ||
        text.contains('wool') ||
        text.contains('jacket')) {
      return ClimateBand.cold;
    }
    if (text.contains('rain')) {
      return ClimateBand.rainy;
    }
    if (text.contains('linen') ||
        text.contains('tank') ||
        text.contains('short')) {
      return ClimateBand.hot;
    }
    if (text.contains('light')) {
      return ClimateBand.warm;
    }
    return ClimateBand.mild;
  }

  DressCode _deriveDressCode(Cloth cloth) {
    final text =
        '${cloth.brand ?? ''} ${cloth.description ?? ''} ${cloth.type ?? ''}'
            .toLowerCase();
    if (text.contains('black tie')) {
      return DressCode.blackTie;
    }
    if (text.contains('formal') ||
        text.contains('gucci') ||
        text.contains('prada')) {
      return DressCode.formal;
    }
    if (text.contains('blazer') || text.contains('button')) {
      return DressCode.businessCasual;
    }
    if (text.contains('smart') || text.contains('dress')) {
      return DressCode.smartCasual;
    }
    return DressCode.relaxed;
  }

  SilhouetteProfile _deriveSilhouette(Cloth cloth) {
    final text =
        '${cloth.description ?? ''} ${cloth.type ?? ''} ${cloth.size ?? ''}'
            .toLowerCase();
    if (text.contains('oversized')) {
      return SilhouetteProfile.oversized;
    }
    if (text.contains('structured') || text.contains('blazer')) {
      return SilhouetteProfile.structured;
    }
    if (text.contains('taper')) {
      return SilhouetteProfile.tapered;
    }
    if (text.contains('slim') || text.contains('fit')) {
      return SilhouetteProfile.fitted;
    }
    if (text.contains('loose') || text.contains('relaxed')) {
      return SilhouetteProfile.relaxed;
    }
    return SilhouetteProfile.balanced;
  }

  bool _isAdjacentDressCode(DressCode source, DressCode target) {
    final sourceIndex = DressCode.values.indexOf(source);
    final targetIndex = DressCode.values.indexOf(target);
    return (sourceIndex - targetIndex).abs() == 1;
  }

  bool _compatibleSilhouettes(
    SilhouetteProfile source,
    SilhouetteProfile target,
  ) {
    const compatibility = {
      SilhouetteProfile.fitted: {
        SilhouetteProfile.structured,
        SilhouetteProfile.tapered,
      },
      SilhouetteProfile.relaxed: {
        SilhouetteProfile.oversized,
        SilhouetteProfile.balanced,
      },
      SilhouetteProfile.balanced: {
        SilhouetteProfile.fitted,
        SilhouetteProfile.relaxed,
      },
      SilhouetteProfile.structured: {
        SilhouetteProfile.fitted,
        SilhouetteProfile.balanced,
      },
      SilhouetteProfile.oversized: {
        SilhouetteProfile.relaxed,
      },
      SilhouetteProfile.tapered: {
        SilhouetteProfile.fitted,
        SilhouetteProfile.structured,
      },
    };

    return compatibility[source]?.contains(target) ?? false;
  }

  List<OccasionTag> _matchOccasions(List<Cloth> clothes, StyleBrief brief) {
    final derived = _deriveOccasions(clothes);
    return derived.where(brief.occasionTags.contains).toList();
  }

  String _buildTitle(StyleBrief brief, Cloth top, Cloth bottom) {
    return '${brief.focusLabel} look: ${top.color ?? top.brand ?? 'Top'} + '
        '${bottom.color ?? bottom.brand ?? 'Bottom'}';
  }

  String _buildReason({
    required StyleBrief brief,
    required double score,
    required double occasionScore,
    required double climateScore,
    required double dressCodeScore,
  }) {
    return 'Matched ${brief.occasionTags.isEmpty ? 'general' : 'occasion'} signals '
        'with a score of ${score.toStringAsFixed(1)}. '
        'Occasion ${occasionScore.toStringAsFixed(1)}, climate ${climateScore.toStringAsFixed(1)}, '
        'dress code ${dressCodeScore.toStringAsFixed(1)}.';
  }

  List<String> _buildStylingNotes(List<Cloth> clothes, StyleBrief brief) {
    final notes = <String>[
      'This plan starts from your existing inventory first.',
      'The engine is checking occasion, climate, dress code, silhouette, and reuse instead of raw text matches.',
    ];

    if (brief.focus == PlanningFocus.trip) {
      notes.add(
          'These pieces were ranked for reusability across multiple days.');
    }
    if (brief.dressCode.index >= DressCode.smartCasual.index) {
      notes.add('Accessories help the look meet the requested dress code.');
    }
    if (clothes.length < 3) {
      notes.add('A third layer or accessory could sharpen the silhouette.');
    }

    return notes;
  }

  bool _needsPurchase(double score, List<Cloth> clothes, StyleBrief brief) {
    final matchedOccasions = _matchOccasions(clothes, brief).length;
    return score < 9 || matchedOccasions < brief.occasionTags.length;
  }

  String _suggestMissingCategory(List<Cloth> clothes, StyleBrief brief) {
    final hasAccessory = clothes
        .any((cloth) => (cloth.type ?? '').toLowerCase() == 'accessories');
    if (!hasAccessory && brief.dressCode.index >= DressCode.smartCasual.index) {
      return 'Accessories';
    }

    final climateReady =
        clothes.any((cloth) => _deriveClimate(cloth) == brief.climate);
    if (!climateReady) {
      return 'Layering Piece';
    }

    return 'Statement Piece';
  }

  PurchaseSuggestion _buildPurchaseSuggestion({
    required String itemType,
    required List<Cloth> existingCloset,
    required StyleBrief brief,
  }) {
    final pairings = existingCloset.take(3).map((cloth) {
      final descriptor = '${cloth.color ?? 'neutral'} ${cloth.type ?? 'piece'}';
      return 'Use the new $itemType with your $descriptor for ${brief.focusLabel.toLowerCase()} looks.';
    }).toList();

    return PurchaseSuggestion(
      itemType: itemType,
      reason:
          'Buy only if the current closet still misses the requested occasion, climate, dress code, or silhouette.',
      pairingIdeas: pairings.isEmpty
          ? [
              'Choose a neutral item with high reuse potential across your current closet.'
            ]
          : pairings,
      unlockedOccasions: brief.occasionTags,
    );
  }
}
