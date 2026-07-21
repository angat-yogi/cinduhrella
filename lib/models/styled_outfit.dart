import 'package:cloud_firestore/cloud_firestore.dart';

import 'cloth.dart';

class StyledOutfitPlacement {
  final String placementId;
  final Cloth cloth;
  final String category;
  final double normalizedDx;
  final double normalizedDy;
  final double scale;
  final int zIndex;
  final int quarterTurns;

  const StyledOutfitPlacement({
    required this.placementId,
    required this.cloth,
    required this.category,
    required this.normalizedDx,
    required this.normalizedDy,
    required this.scale,
    required this.zIndex,
    this.quarterTurns = 0,
  });

  factory StyledOutfitPlacement.fromJson(Map<String, dynamic> json) {
    final position = (json['position'] as Map<String, dynamic>?) ?? {};
    return StyledOutfitPlacement(
      placementId: (json['placementId'] ?? '') as String,
      cloth: Cloth.fromJson((json['cloth'] as Map<String, dynamic>?) ?? {}),
      category: ((json['category'] ?? 'accessory') as String).toLowerCase(),
      normalizedDx:
          ((position['dx'] ?? json['normalizedDx'] ?? 0.5) as num).toDouble(),
      normalizedDy:
          ((position['dy'] ?? json['normalizedDy'] ?? 0.5) as num).toDouble(),
      scale: ((json['scale'] ?? 1.0) as num).toDouble(),
      zIndex: ((json['zIndex'] ?? 0) as num).toInt(),
      quarterTurns: ((json['quarterTurns'] ?? 0) as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'placementId': placementId,
      'cloth': cloth.toJson(),
      'category': category,
      'position': {
        'dx': normalizedDx,
        'dy': normalizedDy,
      },
      'scale': scale,
      'zIndex': zIndex,
      'quarterTurns': quarterTurns,
    };
  }
}

class StyledOutfit {
  String? outfitId;
  String uid;
  String name;
  List<Cloth> clothes;
  List<StyledOutfitPlacement> placements;
  Timestamp createdAt;
  Timestamp? updatedAt;
  bool liked;
  String notes;

  StyledOutfit({
    this.outfitId,
    required this.uid,
    required this.clothes,
    required this.createdAt,
    this.updatedAt,
    this.liked = false,
    required this.name,
    this.notes = '',
    List<StyledOutfitPlacement>? placements,
  }) : placements = placements ?? const [];

  bool get hasPlacements => placements.isNotEmpty;

  StyledOutfit copyWith({
    String? outfitId,
    String? uid,
    String? name,
    List<Cloth>? clothes,
    List<StyledOutfitPlacement>? placements,
    Timestamp? createdAt,
    Timestamp? updatedAt,
    bool? liked,
    String? notes,
  }) {
    return StyledOutfit(
      outfitId: outfitId ?? this.outfitId,
      uid: uid ?? this.uid,
      name: name ?? this.name,
      clothes: clothes ?? this.clothes,
      placements: placements ?? this.placements,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      liked: liked ?? this.liked,
      notes: notes ?? this.notes,
    );
  }

  StyledOutfit.fromJson(Map<String, dynamic> json)
      : outfitId = json['outfitId'],
        uid = json['uid'] ?? '',
        name = json['name'] ?? 'Unnamed Outfit',
        createdAt = json['createdAt'] ?? Timestamp.now(),
        updatedAt = json['updatedAt'],
        liked = json['liked'] ?? false,
        notes = json['notes'] ?? '',
        clothes = ((json['clothes'] as List<dynamic>?) ?? const [])
            .map((item) => Cloth.fromJson(item as Map<String, dynamic>))
            .toList(),
        placements = ((json['placements'] as List<dynamic>?) ?? const [])
            .map(
              (item) => StyledOutfitPlacement.fromJson(
                item as Map<String, dynamic>,
              ),
            )
            .toList();

  Map<String, dynamic> toJson() {
    return {
      'outfitId': outfitId,
      'uid': uid,
      'name': name,
      'notes': notes,
      'createdAt': createdAt,
      'updatedAt': updatedAt ?? Timestamp.now(),
      'liked': liked,
      'clothes': clothes.map((cloth) => cloth.toJson()).toList(),
      'placements': placements.map((placement) => placement.toJson()).toList(),
    };
  }

  factory StyledOutfit.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StyledOutfit.fromJson({
      ...data,
      'outfitId': doc.id,
    });
  }
}
