import 'package:cached_network_image/cached_network_image.dart';
import 'package:cinduhrella/models/cloth.dart';
import 'package:cinduhrella/models/styled_outfit.dart';
import 'package:cinduhrella/services/alert_service.dart';
import 'package:cinduhrella/services/database_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum StudioCategory {
  top,
  bottom,
  accessory,
}

class PlacedStudioItem {
  final String placementId;
  final Cloth cloth;
  final StudioCategory category;
  final Offset normalizedPosition;
  final double scale;
  final int zIndex;
  final int quarterTurns;

  const PlacedStudioItem({
    required this.placementId,
    required this.cloth,
    required this.category,
    required this.normalizedPosition,
    required this.scale,
    required this.zIndex,
    this.quarterTurns = 0,
  });

  PlacedStudioItem copyWith({
    Offset? normalizedPosition,
    double? scale,
    int? zIndex,
    int? quarterTurns,
  }) {
    return PlacedStudioItem(
      placementId: placementId,
      cloth: cloth,
      category: category,
      normalizedPosition: normalizedPosition ?? this.normalizedPosition,
      scale: scale ?? this.scale,
      zIndex: zIndex ?? this.zIndex,
      quarterTurns: quarterTurns ?? this.quarterTurns,
    );
  }
}

class MixMatchStudioPage extends StatefulWidget {
  final String userId;
  final int refreshToken;

  const MixMatchStudioPage({
    required this.userId,
    this.refreshToken = 0,
    super.key,
  });

  @override
  State<MixMatchStudioPage> createState() => _MixMatchStudioPageState();
}

class _MixMatchStudioPageState extends State<MixMatchStudioPage> {
  static const String _introSeenKey = 'mix_match_studio_intro_seen_v1';

  final GetIt _getIt = GetIt.instance;
  late final DatabaseService _databaseService;
  late final AlertService _alertService;

  final List<Cloth> _tops = [];
  final List<Cloth> _bottoms = [];
  final List<Cloth> _accessories = [];
  final List<PlacedStudioItem> _placedItems = [];

  bool _loading = true;
  bool _saving = false;
  bool _showIntro = false;
  bool _showActionMenu = false;
  String? _selectedPlacementId;
  int _zCounter = 0;
  StudioCategory _selectedLibraryCategory = StudioCategory.top;

  static const Map<StudioCategory, int> _categoryLimits = {
    StudioCategory.top: 2,
    StudioCategory.bottom: 2,
    StudioCategory.accessory: 3,
  };

  @override
  void initState() {
    super.initState();
    _databaseService = _getIt.get<DatabaseService>();
    _alertService = _getIt.get<AlertService>();
    _initializeStudio();
  }

  @override
  void didUpdateWidget(covariant MixMatchStudioPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.refreshToken != oldWidget.refreshToken) {
      _loadStudioData();
    }
  }

  Future<void> _initializeStudio() async {
    final preferences = await SharedPreferences.getInstance();
    final showIntro = !(preferences.getBool(_introSeenKey) ?? false);
    if (mounted) {
      setState(() {
        _showIntro = showIntro;
      });
    }
    await _loadStudioData();
  }

  Future<void> _dismissIntro() async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_introSeenKey, true);
    if (!mounted) {
      return;
    }
    setState(() {
      _showIntro = false;
    });
  }

  Future<void> _loadStudioData() async {
    setState(() {
      _loading = true;
    });

    final categorizedItems =
        await _databaseService.fetchUserItems(widget.userId);
    final tops =
        (categorizedItems['top wear'] ?? []).map(Cloth.fromMap).toList();
    final bottoms =
        (categorizedItems['bottom wear'] ?? []).map(Cloth.fromMap).toList();
    final accessories =
        (categorizedItems['accessories'] ?? []).map(Cloth.fromMap).toList();

    if (!mounted) {
      return;
    }

    setState(() {
      _tops
        ..clear()
        ..addAll(tops);
      _bottoms
        ..clear()
        ..addAll(bottoms);
      _accessories
        ..clear()
        ..addAll(accessories);
      _loading = false;
    });
  }

  StudioCategory _categoryForCloth(Cloth cloth) {
    final type = (cloth.type ?? '').toLowerCase();
    if (type == 'top wear') {
      return StudioCategory.top;
    }
    if (type == 'bottom wear') {
      return StudioCategory.bottom;
    }
    return StudioCategory.accessory;
  }

  String _clothLabel(Cloth cloth) {
    final description = (cloth.description ?? '').trim();
    if (description.isNotEmpty) {
      return description;
    }
    final brand = (cloth.brand ?? '').trim();
    if (brand.isNotEmpty) {
      return brand;
    }
    return cloth.type ?? 'Closet item';
  }

  Color _accentForCategory(StudioCategory category) {
    switch (category) {
      case StudioCategory.top:
        return const Color(0xFFDB6C63);
      case StudioCategory.bottom:
        return const Color(0xFF4D6CFA);
      case StudioCategory.accessory:
        return const Color(0xFF10A37F);
    }
  }

  Offset _defaultPositionFor(StudioCategory category, int categoryCount) {
    switch (category) {
      case StudioCategory.top:
        return categoryCount == 0
            ? const Offset(0.50, 0.28)
            : const Offset(0.50, 0.18);
      case StudioCategory.bottom:
        return categoryCount == 0
            ? const Offset(0.50, 0.56)
            : const Offset(0.50, 0.68);
      case StudioCategory.accessory:
        return switch (categoryCount) {
          0 => const Offset(0.33, 0.82),
          1 => const Offset(0.67, 0.82),
          _ => const Offset(0.50, 0.74),
        };
    }
  }

  double _defaultScaleFor(StudioCategory category) {
    switch (category) {
      case StudioCategory.top:
        return 1.0;
      case StudioCategory.bottom:
        return 1.08;
      case StudioCategory.accessory:
        return 0.72;
    }
  }

  bool _alreadyPlaced(Cloth cloth) {
    return _placedItems.any((item) => item.cloth.clothId == cloth.clothId);
  }

  List<Cloth> _availableItems(List<Cloth> items) {
    final placedIds = _placedItems.map((item) => item.cloth.clothId).toSet();
    return items.where((cloth) => !placedIds.contains(cloth.clothId)).toList();
  }

  int _categoryCount(StudioCategory category) {
    return _placedItems.where((item) => item.category == category).length;
  }

  void _placeCloth(Cloth cloth) {
    final category = _categoryForCloth(cloth);
    final existingCount = _categoryCount(category);
    final limit = _categoryLimits[category] ?? 1;

    if (_alreadyPlaced(cloth)) {
      _alertService.showToast(
        text: 'That piece is already in the look.',
        icon: Icons.layers_clear_outlined,
      );
      return;
    }

    if (existingCount >= limit) {
      _alertService.showToast(
        text:
            'You can place up to $limit ${category.name}${limit > 1 ? 's' : ''} at once.',
        icon: Icons.rule_folder_outlined,
      );
      return;
    }

    if (_showIntro) {
      _dismissIntro();
    }

    final placed = PlacedStudioItem(
      placementId:
          '${cloth.clothId ?? cloth.imageUrl}-${DateTime.now().microsecondsSinceEpoch}',
      cloth: cloth,
      category: category,
      normalizedPosition: _defaultPositionFor(category, existingCount),
      scale: _defaultScaleFor(category),
      zIndex: _zCounter++,
    );

    setState(() {
      _placedItems.add(placed);
      _selectedPlacementId = placed.placementId;
    });
  }

  void _removePlacement(String placementId) {
    setState(() {
      _placedItems.removeWhere((item) => item.placementId == placementId);
      if (_selectedPlacementId == placementId) {
        _selectedPlacementId = null;
      }
    });
  }

  void _clearBoard() {
    setState(() {
      _placedItems.clear();
      _selectedPlacementId = null;
      _showActionMenu = false;
    });
  }

  void _bringToFront(String placementId) {
    final index =
        _placedItems.indexWhere((item) => item.placementId == placementId);
    if (index < 0) {
      return;
    }
    final updated = _placedItems[index].copyWith(zIndex: _zCounter++);
    setState(() {
      _placedItems[index] = updated;
      _selectedPlacementId = placementId;
    });
  }

  void _resizeSelected(double delta) {
    final placementId = _selectedPlacementId;
    if (placementId == null) {
      return;
    }
    final index =
        _placedItems.indexWhere((item) => item.placementId == placementId);
    if (index < 0) {
      return;
    }
    final nextScale = (_placedItems[index].scale + delta).clamp(0.45, 1.7);
    setState(() {
      _placedItems[index] = _placedItems[index].copyWith(scale: nextScale);
    });
  }

  void _rotatePlacement(String placementId) {
    final index =
        _placedItems.indexWhere((item) => item.placementId == placementId);
    if (index < 0) {
      return;
    }
    final current = _placedItems[index];
    setState(() {
      _selectedPlacementId = placementId;
      _placedItems[index] = current.copyWith(
        quarterTurns: (current.quarterTurns + 1) % 4,
        zIndex: _zCounter++,
      );
    });
  }

  Future<void> _saveLook() async {
    if (_placedItems.isEmpty) {
      _alertService.showToast(
        text: 'Add a few pieces before saving the look.',
        icon: Icons.error_outline,
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final outfitRef = FirebaseFirestore.instance
          .collection('users/${widget.userId}/styledOutfits')
          .doc();
      final outfit = StyledOutfit(
        outfitId: outfitRef.id,
        uid: widget.userId,
        name: _buildOutfitName(),
        clothes: _placedItems.map((item) => item.cloth).toList(),
        createdAt: Timestamp.now(),
      );
      await outfitRef.set(outfit.toJson());
      if (!mounted) {
        return;
      }
      _alertService.showToast(
        text: 'Look saved to your outfit library.',
        icon: Icons.check_circle_outline,
      );
      setState(() {
        _showActionMenu = false;
      });
    } catch (_) {
      _alertService.showToast(
        text: 'Could not save this look.',
        icon: Icons.error_outline,
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  String _buildOutfitName() {
    final leadPieces =
        _placedItems.take(3).map((item) => _clothLabel(item.cloth)).toList();
    return leadPieces.isEmpty ? 'Studio look' : leadPieces.join(' + ');
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F1EB),
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 196),
                child: _buildPlayground(),
              ),
            ),
            Positioned(
              top: 14,
              left: 16,
              right: 16,
              child: _buildStudioTopBar(),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 154,
              child: _buildBottomSelectionToolbar(),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: _buildWardrobeTray(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudioTopBar() {
    return Align(
      alignment: Alignment.topRight,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        child:
            _showActionMenu ? _buildExpandedActionMenu() : _buildMenuTrigger(),
      ),
    );
  }

  Widget _buildMenuTrigger() {
    return Container(
      key: const ValueKey('studio-menu-trigger'),
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _showActionMenu = true;
          });
        },
        borderRadius: BorderRadius.circular(999),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF6D56A8),
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6D56A8).withValues(alpha: 0.24),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Icon(
            Icons.more_horiz_rounded,
            color: Colors.white,
            size: 24,
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedActionMenu() {
    return Container(
      key: const ValueKey('studio-menu-expanded'),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildMenuAction(
            icon: Icons.bookmark_added_outlined,
            label: _saving ? 'Saving...' : 'Save look',
            onTap: _saving ? null : _saveLook,
            accent: const Color(0xFF6D56A8),
          ),
          const SizedBox(height: 8),
          _buildMenuAction(
            icon: Icons.refresh_rounded,
            label: 'Refresh tray',
            onTap: () async {
              await _loadStudioData();
              if (!mounted) {
                return;
              }
              setState(() {
                _showActionMenu = false;
              });
            },
          ),
          const SizedBox(height: 8),
          _buildMenuAction(
            icon: Icons.restart_alt_rounded,
            label: 'Clear canvas',
            onTap: _placedItems.isEmpty ? null : _clearBoard,
          ),
          const SizedBox(height: 8),
          _buildMenuAction(
            icon: Icons.close_rounded,
            label: 'Close',
            onTap: () {
              setState(() {
                _showActionMenu = false;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuAction({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    Color? accent,
  }) {
    final enabled = onTap != null;
    final foreground = accent ?? Colors.black.withValues(alpha: 0.78);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: enabled
              ? Colors.black.withValues(alpha: 0.03)
              : Colors.black.withValues(alpha: 0.015),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color:
                  enabled ? foreground : Colors.black.withValues(alpha: 0.24),
            ),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: enabled
                    ? Colors.black.withValues(alpha: 0.78)
                    : Colors.black.withValues(alpha: 0.28),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDraggableCard(Cloth cloth, StudioCategory category) {
    final accent = _accentForCategory(category);
    final card = _buildClosetCard(
      cloth: cloth,
      accent: accent,
      compact: true,
    );
    return LongPressDraggable<Cloth>(
      data: cloth,
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: 96,
          height: 128,
          child: _buildClosetCard(
            cloth: cloth,
            accent: accent,
            compact: false,
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.25,
        child: card,
      ),
      child: GestureDetector(
        onDoubleTap: () => _placeCloth(cloth),
        child: card,
      ),
    );
  }

  Widget _buildClosetCard({
    required Cloth cloth,
    required Color accent,
    required bool compact,
  }) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
        color: Colors.white,
        boxShadow: compact
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CachedNetworkImage(
              imageUrl: cloth.imageUrl ?? '',
              width: double.infinity,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: Colors.black12,
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.black12,
                alignment: Alignment.center,
                child: const Icon(Icons.broken_image_outlined),
              ),
            ),
          ),
          Positioned(
            right: 8,
            bottom: 8,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: accent,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayground() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(38),
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFFFCFA),
            Color(0xFFF4F2FF),
          ],
          stops: [0.15, 1],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 30,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(38),
        child: DragTarget<Cloth>(
          onAcceptWithDetails: (details) {
            _placeCloth(details.data);
          },
          builder: (context, candidateData, rejectedData) {
            final highlight = candidateData.isNotEmpty;
            return Stack(
              children: [
                Positioned.fill(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: highlight
                            ? const Color(0xFF6F61E8)
                            : Colors.black.withValues(alpha: 0.06),
                        width: highlight ? 2.2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(38),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: InteractiveViewer(
                    minScale: 0.85,
                    maxScale: 2.4,
                    boundaryMargin: const EdgeInsets.all(60),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final sortedItems = [..._placedItems]
                          ..sort((a, b) => a.zIndex.compareTo(b.zIndex));
                        return Stack(
                          children: [
                            Positioned.fill(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: RadialGradient(
                                    colors: [
                                      Colors.white.withValues(alpha: 0.9),
                                      const Color(0xFFF0EEFF),
                                    ],
                                    center: const Alignment(0, -0.25),
                                    radius: 1.0,
                                  ),
                                ),
                              ),
                            ),
                            ...sortedItems.map(
                              (item) => _buildPlacedItem(
                                item,
                                constraints.maxWidth,
                                constraints.maxHeight,
                              ),
                            ),
                            if (_showIntro)
                              Positioned(
                                left: 24,
                                right: 24,
                                bottom: 28,
                                child: _buildIntroCard(),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                Positioned(
                  top: 28,
                  left: 20,
                  child: _buildLimitBadge(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPlacedItem(
    PlacedStudioItem item,
    double boardWidth,
    double boardHeight,
  ) {
    final accent = _accentForCategory(item.category);
    final isSelected = _selectedPlacementId == item.placementId;
    final contentWidth = _baseWidthFor(item.category) * item.scale;
    final contentHeight = _baseHeightFor(item.category) * item.scale;
    final rotatesBounds = item.quarterTurns.isOdd;
    final width = rotatesBounds ? contentHeight : contentWidth;
    final height = rotatesBounds ? contentWidth : contentHeight;
    final dx = (item.normalizedPosition.dx * boardWidth) - (width / 2);
    final dy = (item.normalizedPosition.dy * boardHeight) - (height / 2);

    final maxLeft = boardWidth > width ? boardWidth - width : 0.0;
    final maxTop = boardHeight > height ? boardHeight - height : 0.0;

    return Positioned(
      left: dx.clamp(0, maxLeft),
      top: dy.clamp(0, maxTop),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedPlacementId = item.placementId;
          });
          _bringToFront(item.placementId);
        },
        onDoubleTap: () => _removePlacement(item.placementId),
        onPanStart: (_) => _bringToFront(item.placementId),
        onPanUpdate: (details) {
          final index = _placedItems.indexWhere(
            (element) => element.placementId == item.placementId,
          );
          if (index < 0) {
            return;
          }
          final current = _placedItems[index];
          final next = Offset(
            current.normalizedPosition.dx + (details.delta.dx / boardWidth),
            current.normalizedPosition.dy + (details.delta.dy / boardHeight),
          );
          setState(() {
            _selectedPlacementId = item.placementId;
            _placedItems[index] = current.copyWith(
              normalizedPosition: Offset(
                next.dx.clamp(0.12, 0.88),
                next.dy.clamp(0.10, 0.90),
              ),
            );
          });
        },
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              width: width,
              height: height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color:
                      isSelected ? accent : Colors.white.withValues(alpha: 0.5),
                  width: isSelected ? 2.6 : 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black
                        .withValues(alpha: isSelected ? 0.18 : 0.10),
                    blurRadius: isSelected ? 22 : 14,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: RotatedBox(
                  quarterTurns: item.quarterTurns,
                  child: SizedBox(
                    width: contentWidth,
                    height: contentHeight,
                    child: CachedNetworkImage(
                      imageUrl: item.cloth.imageUrl ?? '',
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.black12,
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.black12,
                        alignment: Alignment.center,
                        child: const Icon(Icons.broken_image_outlined),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: -8,
              right: -8,
              child: InkWell(
                onTap: () => _rotatePlacement(item.placementId),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black.withValues(alpha: 0.78),
                    border: Border.all(color: Colors.white),
                  ),
                  child: const Icon(
                    Icons.rotate_right,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _baseWidthFor(StudioCategory category) {
    switch (category) {
      case StudioCategory.top:
        return 150;
      case StudioCategory.bottom:
        return 156;
      case StudioCategory.accessory:
        return 92;
    }
  }

  double _baseHeightFor(StudioCategory category) {
    switch (category) {
      case StudioCategory.top:
        return 150;
      case StudioCategory.bottom:
        return 176;
      case StudioCategory.accessory:
        return 92;
    }
  }

  Widget _buildLimitBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '2 • 2 • 3',
            style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildIntroCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF6D56A8).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.touch_app_outlined,
              color: Color(0xFF6D56A8),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Double tap an item below to place it on the canvas. Drag to move it, use the toolbar to resize it, and double tap it again to send it back to the wardrobe.',
              style: TextStyle(
                height: 1.4,
                color: Colors.black.withValues(alpha: 0.72),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _dismissIntro,
            icon: const Icon(Icons.close),
            tooltip: 'Dismiss',
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionToolbar() {
    final selected = _selectedPlacementId != null;
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: selected ? () => _resizeSelected(-0.08) : null,
            icon: const Icon(Icons.zoom_out_map),
            tooltip: 'Make smaller',
          ),
          IconButton(
            onPressed: selected ? () => _resizeSelected(0.08) : null,
            icon: const Icon(Icons.zoom_in),
            tooltip: 'Make larger',
          ),
          IconButton(
            onPressed:
                selected ? () => _removePlacement(_selectedPlacementId!) : null,
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Remove',
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSelectionToolbar() {
    final selected = _selectedPlacementId != null;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 160),
      opacity: selected ? 1 : 0,
      child: IgnorePointer(
        ignoring: !selected,
        child: Align(
          alignment: Alignment.centerRight,
          child: _buildSelectionToolbar(),
        ),
      ),
    );
  }

  List<Cloth> _itemsForSelectedCategory() {
    switch (_selectedLibraryCategory) {
      case StudioCategory.top:
        return _tops;
      case StudioCategory.bottom:
        return _bottoms;
      case StudioCategory.accessory:
        return _accessories;
    }
  }

  String _titleForCategory(StudioCategory category) {
    switch (category) {
      case StudioCategory.top:
        return 'Top wear';
      case StudioCategory.bottom:
        return 'Bottom wear';
      case StudioCategory.accessory:
        return 'Accessories';
    }
  }

  IconData _iconForCategory(StudioCategory category) {
    switch (category) {
      case StudioCategory.top:
        return Icons.checkroom_outlined;
      case StudioCategory.bottom:
        return Icons.straighten_outlined;
      case StudioCategory.accessory:
        return Icons.workspace_premium_outlined;
    }
  }

  Widget _buildCategoryChip(StudioCategory category) {
    final selected = _selectedLibraryCategory == category;
    final accent = _accentForCategory(category);
    return InkWell(
      onTap: () {
        setState(() {
          _selectedLibraryCategory = category;
        });
      },
      borderRadius: BorderRadius.circular(999),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: 0.14)
              : Colors.black.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? accent.withValues(alpha: 0.28)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_iconForCategory(category), size: 17, color: accent),
            const SizedBox(width: 8),
            Text(
              _titleForCategory(category),
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Colors.black.withValues(alpha: 0.82),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWardrobeTray() {
    final items = _availableItems(_itemsForSelectedCategory());
    return Container(
      height: 148,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 26,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildCategoryChip(StudioCategory.top),
                      const SizedBox(width: 8),
                      _buildCategoryChip(StudioCategory.bottom),
                      const SizedBox(width: 8),
                      _buildCategoryChip(StudioCategory.accessory),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${items.length} items',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black.withValues(alpha: 0.55),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Text(
                      'No ${_titleForCategory(_selectedLibraryCategory).toLowerCase()} yet.',
                      style: TextStyle(
                        color: Colors.black.withValues(alpha: 0.55),
                      ),
                    ),
                  )
                : ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      return SizedBox(
                        width: 82,
                        child: _buildDraggableCard(
                          items[index],
                          _selectedLibraryCategory,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
