enum PlanningFocus { trip, event, mood, everyday }

enum OccasionTag {
  casual,
  work,
  dinner,
  wedding,
  vacation,
  outdoors,
  party,
  lounge,
}

enum ClimateBand { cold, mild, warm, hot, rainy }

enum DressCode { relaxed, smartCasual, businessCasual, formal, blackTie }

enum SilhouetteProfile {
  fitted,
  balanced,
  relaxed,
  oversized,
  tapered,
  structured
}

class StyleBrief {
  final PlanningFocus focus;
  final String title;
  final String context;
  final String mood;
  final int tripDays;
  final ClimateBand climate;
  final DressCode dressCode;
  final SilhouetteProfile silhouette;
  final List<OccasionTag> occasionTags;

  const StyleBrief({
    required this.focus,
    required this.title,
    required this.context,
    required this.mood,
    required this.climate,
    required this.dressCode,
    required this.silhouette,
    required this.occasionTags,
    this.tripDays = 1,
  });

  bool get isEmpty =>
      title.trim().isEmpty &&
      context.trim().isEmpty &&
      mood.trim().isEmpty &&
      occasionTags.isEmpty;

  String get focusLabel {
    switch (focus) {
      case PlanningFocus.trip:
        return 'Trip';
      case PlanningFocus.event:
        return 'Event';
      case PlanningFocus.mood:
        return 'Mood';
      case PlanningFocus.everyday:
        return 'Everyday';
    }
  }
}
