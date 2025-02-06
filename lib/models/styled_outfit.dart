import 'package:cloud_firestore/cloud_firestore.dart';
import 'cloth.dart';

class StyledOutfit {
  String? outfitId;
  String uid;
  List<Cloth> clothes;
  Timestamp createdAt;
  bool liked; // ✅ New field added

  StyledOutfit({
    this.outfitId,
    required this.uid,
    required this.clothes,
    required this.createdAt,
    this.liked = false, // Default to false
  });

  StyledOutfit.fromJson(Map<String, dynamic> json)
      : outfitId = json['outfitId'],
        uid = json['uid'],
        createdAt = json['createdAt'] ?? Timestamp.now(),
        liked = json['liked'] ?? false, // ✅ Fetch 'liked' from Firestore
        clothes = (json['clothes'] as List<dynamic>)
            .map((item) => Cloth.fromJson(item))
            .toList();

  Map<String, dynamic> toJson() {
    return {
      'outfitId': outfitId,
      'uid': uid,
      'createdAt': createdAt,
      'liked': liked, // ✅ Save like status in Firestore
      'clothes': clothes.map((cloth) => cloth.toJson()).toList(),
    };
  }
}
