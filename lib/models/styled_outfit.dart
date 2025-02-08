import 'package:cloud_firestore/cloud_firestore.dart';
import 'cloth.dart';

class StyledOutfit {
  String? outfitId;
  String uid;
  String name;
  List<Cloth> clothes;
  Timestamp createdAt;
  bool liked;

  StyledOutfit({
    this.outfitId,
    required this.uid,
    required this.clothes,
    required this.createdAt,
    this.liked = false,
    required this.name, // ✅ Name is now required
  });

  StyledOutfit.fromJson(Map<String, dynamic> json)
      : outfitId = json['outfitId'],
        uid = json['uid'],
        name = json['name'] ?? 'Unnamed Outfit', // ✅ Ensure name is loaded
        createdAt = json['createdAt'] ?? Timestamp.now(),
        liked = json['liked'] ?? false,
        clothes = (json['clothes'] as List<dynamic>)
            .map((item) => Cloth.fromJson(item))
            .toList();

  Map<String, dynamic> toJson() {
    return {
      'outfitId': outfitId,
      'uid': uid,
      'name': name, // ✅ Save name
      'createdAt': createdAt,
      'liked': liked,
      'clothes': clothes.map((cloth) => cloth.toJson()).toList(),
    };
  }

  factory StyledOutfit.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return StyledOutfit(
      outfitId: doc.id,
      uid: data['uid'] ?? '',
      name: data['name'] ?? 'Unnamed Outfit', // ✅ Load name from Firestore
      createdAt: data['createdAt'] ?? Timestamp.now(),
      liked: data['liked'] ?? false,
      clothes: (data['clothes'] as List<dynamic>)
          .map((item) => Cloth.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
