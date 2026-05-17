import 'package:cinduhrella/models/cloth.dart';
import 'package:cinduhrella/models/style_brief.dart';
import 'package:cinduhrella/models/try_on.dart';

class PurchaseSuggestion {
  final String itemType;
  final String reason;
  final List<String> pairingIdeas;
  final List<OccasionTag> unlockedOccasions;

  const PurchaseSuggestion({
    required this.itemType,
    required this.reason,
    required this.pairingIdeas,
    required this.unlockedOccasions,
  });
}

class RecommendationBreakdown {
  final double occasionScore;
  final double climateScore;
  final double dressCodeScore;
  final double silhouetteScore;
  final double reuseScore;

  const RecommendationBreakdown({
    required this.occasionScore,
    required this.climateScore,
    required this.dressCodeScore,
    required this.silhouetteScore,
    required this.reuseScore,
  });
}

class OutfitRecommendation {
  final String title;
  final String reason;
  final List<Cloth> clothes;
  final double score;
  final RecommendationBreakdown breakdown;
  final List<String> stylingNotes;
  final List<OccasionTag> matchedOccasions;
  final PurchaseSuggestion? purchaseSuggestion;
  final TryOnPreview? preview;

  const OutfitRecommendation({
    required this.title,
    required this.reason,
    required this.clothes,
    required this.score,
    required this.breakdown,
    required this.stylingNotes,
    required this.matchedOccasions,
    this.purchaseSuggestion,
    this.preview,
  });

  OutfitRecommendation copyWith({
    TryOnPreview? preview,
  }) {
    return OutfitRecommendation(
      title: title,
      reason: reason,
      clothes: clothes,
      score: score,
      breakdown: breakdown,
      stylingNotes: stylingNotes,
      matchedOccasions: matchedOccasions,
      purchaseSuggestion: purchaseSuggestion,
      preview: preview ?? this.preview,
    );
  }
}
