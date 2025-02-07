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

  factory StyledOutfit.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return StyledOutfit(
      outfitId: doc.id, // Firestore document ID
      uid: data['uid'] ?? '', // Ensure uid is provided
      createdAt: data['createdAt'] ??
          Timestamp.now(), // Use Timestamp.now() if missing
      liked: data['liked'] ?? false, // Default to false if not set
      clothes: (data['clothes'] as List<dynamic>).map((item) {
        return Cloth.fromMap(item as Map<String, dynamic>);
      }).toList(),
    );
  }
}
