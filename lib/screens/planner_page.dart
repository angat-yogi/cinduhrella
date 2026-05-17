import 'package:cinduhrella/models/body_measurements.dart';
import 'package:cinduhrella/models/cloth.dart';
import 'package:cinduhrella/models/outfit_recommendation.dart';
import 'package:cinduhrella/models/style_brief.dart';
import 'package:cinduhrella/models/styled_outfit.dart';
import 'package:cinduhrella/models/try_on.dart';
import 'package:cinduhrella/models/user_profile.dart';
import 'package:cinduhrella/services/alert_service.dart';
import 'package:cinduhrella/services/database_service.dart';
import 'package:cinduhrella/services/try_on_service.dart';
import 'package:cinduhrella/services/wardrobe_engine_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

class PlannerPage extends StatefulWidget {
  final String userId;

  const PlannerPage({required this.userId, super.key});

  @override
  State<PlannerPage> createState() => _PlannerPageState();
}

class _PlannerPageState extends State<PlannerPage> {
  final GetIt _getIt = GetIt.instance;
  late final WardrobeEngineService _wardrobeEngineService;
  late final DatabaseService _databaseService;
  late final AlertService _alertService;
  late final TryOnService _tryOnService;

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contextController = TextEditingController();
  final TextEditingController _moodController = TextEditingController();

  PlanningFocus _focus = PlanningFocus.trip;
  ClimateBand _climate = ClimateBand.mild;
  DressCode _dressCode = DressCode.smartCasual;
  SilhouetteProfile _silhouette = SilhouetteProfile.balanced;
  final Set<OccasionTag> _occasionTags = {OccasionTag.casual};
  int _tripDays = 3;
  bool _loading = true;
  bool _generating = false;
  String? _previewingTitle;
  UserProfile? _profile;
  List<OutfitRecommendation> _recommendations = const [];

  @override
  void initState() {
    super.initState();
    _wardrobeEngineService = _getIt.get<WardrobeEngineService>();
    _databaseService = _getIt.get<DatabaseService>();
    _alertService = _getIt.get<AlertService>();
    _tryOnService = _getIt.get<TryOnService>();
    _loadProfileAndRecommendations();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contextController.dispose();
    _moodController.dispose();
    super.dispose();
  }

  Future<void> _loadProfileAndRecommendations() async {
    setState(() {
      _loading = true;
    });

    final profile = await _databaseService.getUserProfile(uid: widget.userId);
    final recommendations = await _wardrobeEngineService.buildRecommendations(
      widget.userId,
      _buildBrief(),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _profile = profile;
      _recommendations = recommendations;
      _loading = false;
    });
  }

  Future<void> _generatePlan() async {
    setState(() {
      _generating = true;
    });

    final recommendations = await _wardrobeEngineService.buildRecommendations(
      widget.userId,
      _buildBrief(),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _recommendations = recommendations;
      _generating = false;
    });
  }

  Future<void> _buildPreview(OutfitRecommendation recommendation) async {
    final profile = _profile;
    if (profile == null) {
      return;
    }

    setState(() {
      _previewingTitle = recommendation.title;
    });

    final preview = await _tryOnService.generatePreview(
      userId: widget.userId,
      profile: profile,
      recommendation: recommendation,
      brief: _buildBrief(),
    );
    final bodyProfile =
        await _tryOnService.getOrCreateDefaultBodyProfile(profile);
    if (bodyProfile != null) {
      final topCloth = _firstMatchingCloth(recommendation.clothes, 'Top Wear');
      final bottomCloth =
          _firstMatchingCloth(recommendation.clothes, 'Bottom Wear');
      if (topCloth != null && bottomCloth != null) {
        final topAsset = await _tryOnService.createGarmentAssetFromCloth(
          userId: widget.userId,
          cloth: topCloth,
          category: 'top',
        );
        final bottomAsset = await _tryOnService.createGarmentAssetFromCloth(
          userId: widget.userId,
          cloth: bottomCloth,
          category: 'bottom',
        );
        await _tryOnService.submitTryOnJob(
          userId: widget.userId,
          bodyProfile: bodyProfile,
          topGarment: topAsset,
          bottomGarment: bottomAsset,
          brief: _buildBrief(),
        );
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _recommendations = _recommendations
          .map(
            (item) => item.title == recommendation.title
                ? item.copyWith(preview: preview)
                : item,
          )
          .toList();
      _previewingTitle = null;
    });
  }

  StyleBrief _buildBrief() {
    return StyleBrief(
      focus: _focus,
      title: _titleController.text.trim(),
      context: _contextController.text.trim(),
      mood: _moodController.text.trim(),
      tripDays: _tripDays,
      climate: _climate,
      dressCode: _dressCode,
      silhouette: _silhouette,
      occasionTags: _occasionTags.toList(),
    );
  }

  Cloth? _firstMatchingCloth(List<Cloth> clothes, String type) {
    for (final cloth in clothes) {
      if ((cloth.type ?? '').toLowerCase() == type.toLowerCase()) {
        return cloth;
      }
    }
    return null;
  }

  Future<void> _saveRecommendation(OutfitRecommendation recommendation) async {
    if (recommendation.clothes.isEmpty) {
      _alertService.showToast(
        text: "Nothing to save from this recommendation yet.",
        icon: Icons.error,
      );
      return;
    }

    final outfitRef = FirebaseFirestore.instance
        .collection('users/${widget.userId}/styledOutfits')
        .doc();

    final outfit = StyledOutfit(
      outfitId: outfitRef.id,
      uid: widget.userId,
      name: recommendation.title,
      clothes: recommendation.clothes,
      createdAt: Timestamp.now(),
    );

    await outfitRef.set(outfit.toJson());
    _alertService.showToast(
      text: "Saved to your outfit library.",
      icon: Icons.check_circle,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Planner"),
        actions: [
          IconButton(
            onPressed: _loadProfileAndRecommendations,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _plannerBriefCard(),
          const SizedBox(height: 16),
          _bodyPreviewCard(
            _profile?.bodyMeasurements ?? const BodyMeasurements(),
          ),
          const SizedBox(height: 16),
          _summaryCard(),
          const SizedBox(height: 16),
          ..._recommendations.map(_recommendationCard),
        ],
      ),
    );
  }

  Widget _plannerBriefCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Wardrobe Engine Brief",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<PlanningFocus>(
              value: _focus,
              decoration: const InputDecoration(
                labelText: "Planning mode",
                border: OutlineInputBorder(),
              ),
              items: PlanningFocus.values
                  .map(
                    (focus) => DropdownMenuItem(
                      value: focus,
                      child: Text(focus.name),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                setState(() {
                  _focus = value;
                });
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: "Trip, event, or purpose",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _moodController,
              decoration: const InputDecoration(
                labelText: "Mood",
                hintText: "polished, cozy, sharp, bold",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contextController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Context",
                hintText: "weather, venue, travel constraints, time of day",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<ClimateBand>(
                    value: _climate,
                    decoration: const InputDecoration(
                      labelText: "Climate",
                      border: OutlineInputBorder(),
                    ),
                    items: ClimateBand.values
                        .map(
                          (item) => DropdownMenuItem(
                            value: item,
                            child: Text(item.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() {
                        _climate = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<DressCode>(
                    value: _dressCode,
                    decoration: const InputDecoration(
                      labelText: "Dress code",
                      border: OutlineInputBorder(),
                    ),
                    items: DressCode.values
                        .map(
                          (item) => DropdownMenuItem(
                            value: item,
                            child: Text(item.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }
                      setState(() {
                        _dressCode = value;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<SilhouetteProfile>(
              value: _silhouette,
              decoration: const InputDecoration(
                labelText: "Silhouette target",
                border: OutlineInputBorder(),
              ),
              items: SilhouetteProfile.values
                  .map(
                    (item) => DropdownMenuItem(
                      value: item,
                      child: Text(item.name),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) {
                  return;
                }
                setState(() {
                  _silhouette = value;
                });
              },
            ),
            const SizedBox(height: 16),
            const Text(
              "Occasions",
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: OccasionTag.values.map((tag) {
                final selected = _occasionTags.contains(tag);
                return FilterChip(
                  label: Text(tag.name),
                  selected: selected,
                  onSelected: (value) {
                    setState(() {
                      if (value) {
                        _occasionTags.add(tag);
                      } else {
                        _occasionTags.remove(tag);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            if (_focus == PlanningFocus.trip) ...[
              const SizedBox(height: 16),
              Text("Trip length: $_tripDays day(s)"),
              Slider(
                min: 1,
                max: 14,
                divisions: 13,
                value: _tripDays.toDouble(),
                onChanged: (value) {
                  setState(() {
                    _tripDays = value.round();
                  });
                },
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _generating ? null : _generatePlan,
                child: Text(
                  _generating ? "Generating..." : "Run Wardrobe Engine",
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bodyPreviewCard(BodyMeasurements measurements) {
    final hasMeasurements = measurements.hasEnoughDataForPreview;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Static Try-On Pipeline",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              hasMeasurements
                  ? "Your measurements are sufficient for body-dummy based previews. The renderer can now prepare a structured payload for a remote image pipeline."
                  : "You still need more body measurement coverage for stronger static try-on previews.",
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _measurementChip("Height", measurements.heightCm),
                _measurementChip("Chest", measurements.chestCm),
                _measurementChip("Waist", measurements.waistCm),
                _measurementChip("Hips", measurements.hipsCm),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard() {
    return Card(
      color: Colors.blueGrey.shade50,
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Engine policy",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              "The engine starts with inventory on hand. It scores outfits against explicit occasion tags, climate, dress code, silhouette, and reuse. It suggests buying only when those constraints cannot be satisfied well enough from the current closet.",
            ),
          ],
        ),
      ),
    );
  }

  Widget _recommendationCard(OutfitRecommendation recommendation) {
    final previewing = _previewingTitle == recommendation.title;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    recommendation.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  recommendation.score.toStringAsFixed(1),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(recommendation.reason),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _scoreChip("Occasion", recommendation.breakdown.occasionScore),
                _scoreChip("Climate", recommendation.breakdown.climateScore),
                _scoreChip("Dress", recommendation.breakdown.dressCodeScore),
                _scoreChip("Shape", recommendation.breakdown.silhouetteScore),
                _scoreChip("Reuse", recommendation.breakdown.reuseScore),
              ],
            ),
            const SizedBox(height: 12),
            if (recommendation.clothes.isNotEmpty)
              SizedBox(
                height: 120,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: recommendation.clothes.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    return _clothCard(recommendation.clothes[index]);
                  },
                ),
              ),
            if (recommendation.stylingNotes.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                "Why it works",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              ...recommendation.stylingNotes.map(
                (note) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text("• $note"),
                ),
              ),
            ],
            if (recommendation.purchaseSuggestion != null) ...[
              const SizedBox(height: 12),
              _purchaseSuggestionCard(recommendation.purchaseSuggestion!),
            ],
            if (recommendation.preview != null) ...[
              const SizedBox(height: 12),
              _previewCard(recommendation.preview!),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed:
                        previewing ? null : () => _buildPreview(recommendation),
                    icon: const Icon(Icons.view_in_ar_outlined),
                    label: Text(
                      previewing ? "Preparing..." : "Generate Static Preview",
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: recommendation.clothes.isEmpty
                        ? null
                        : () => _saveRecommendation(recommendation),
                    icon: const Icon(Icons.bookmark_add_outlined),
                    label: const Text("Save Outfit"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _previewCard(TryOnPreview preview) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.teal.shade50,
        border: Border.all(color: Colors.teal.shade100),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Renderer: ${preview.renderer}",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(preview.summary),
          const SizedBox(height: 8),
          Text(
            preview.readyForRemoteRenderer
                ? "Ready for remote renderer handoff."
                : "Preview spec created, but profile data is still incomplete for full remote rendering.",
          ),
          const SizedBox(height: 8),
          ...preview.layers.map(
            (layer) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text("• ${layer.label}: ${layer.description}"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _clothCard(Cloth cloth) {
    return SizedBox(
      width: 110,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                cloth.imageUrl ?? '',
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.checkroom, size: 36),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            cloth.type ?? "Item",
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Text(
            [cloth.brand, cloth.color]
                .whereType<String>()
                .where((value) => value.isNotEmpty)
                .join(" • "),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _purchaseSuggestionCard(PurchaseSuggestion suggestion) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Buy only if needed: ${suggestion.itemType}",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(suggestion.reason),
          const SizedBox(height: 8),
          ...suggestion.pairingIdeas.map(
            (idea) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text("• $idea"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _measurementChip(String label, double? value) {
    return Chip(
      label: Text(
        value == null
            ? "$label: missing"
            : "$label: ${value.toStringAsFixed(0)} cm",
      ),
    );
  }

  Widget _scoreChip(String label, double score) {
    return Chip(
      label: Text("$label ${score.toStringAsFixed(1)}"),
    );
  }
}
