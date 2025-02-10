import 'package:cinduhrella/models/cloth.dart';
import 'package:cinduhrella/models/social/comment.dart';
import 'package:cinduhrella/models/social/like.dart';
import 'package:cinduhrella/models/styled_outfit.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  String? postId;
  String? uid; // User ID of the person who posted
  String? title;
  String? description;
  List<StyledOutfit>? outfits; // List of outfits associated with the post
  List<Cloth>? clothes; // List of clothes associated with the post
  List<Like>? likes;
  List<Comment>? comments;
  DateTime? timestamp;
  bool isPublic;

  Post({
    required this.postId,
    required this.uid,
    required this.title,
    required this.description,
    required this.outfits,
    required this.clothes,
    this.likes = const [],
    this.comments = const [],
    DateTime? timestamp,
    this.isPublic = false,
  }) : timestamp = timestamp ?? DateTime.now();

  // Named constructor to initialize a Post instance from a JSON object
  Post.fromJson(Map<String, dynamic> json)
      : postId = json['postId'],
        uid = json['uid'],
        title = json['title'],
        description = json['description'],
        outfits = (json['outfits'] as List<dynamic>?)
                ?.map((e) => StyledOutfit.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        clothes = (json['clothes'] as List<dynamic>?)
                ?.map((e) => Cloth.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        likes = (json['likes'] as List<dynamic>?)
                ?.map((e) => Like.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        comments = (json['comments'] as List<dynamic>?)
                ?.map((e) => Comment.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        timestamp = json['timestamp'] != null
            ? DateTime.parse(json['timestamp'])
            : DateTime.now(),
        isPublic = json['isPublic'] ?? false;

  // Converts a Post instance to a JSON object for saving to Firebase
  Map<String, dynamic> toJson() {
    return {
      'postId': postId,
      'uid': uid,
      'title': title,
      'description': description,
      'outfits': outfits?.map((e) => e.toJson()).toList() ?? [],
      'clothes': clothes?.map((e) => e.toJson()).toList() ?? [],
      'likes': likes?.map((e) => e.toJson()).toList() ?? [],
      'comments': comments?.map((e) => e.toJson()).toList() ?? [],
      'timestamp': timestamp?.toIso8601String(),
      'isPublic': isPublic,
    };
  }

  factory Post.fromMap(Map<String, dynamic> map) {
    return Post(
      postId: map['postId'],
      uid: map['uid'],
      title: map['title'],
      description: map['description'],
      outfits: (map['outfits'] as List<dynamic>?)
              ?.map((e) => StyledOutfit.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      clothes: (map['clothes'] as List<dynamic>?)
              ?.map((e) => Cloth.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      likes: (map['likes'] as List<dynamic>?)
              ?.map((e) => Like.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      comments: (map['comments'] as List<dynamic>?)
              ?.map((e) => Comment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      timestamp: map['timestamp'] != null
          ? DateTime.parse(map['timestamp'])
          : DateTime.now(),
      isPublic: map['isPublic'] ?? false,
    );
  }

  // Converts a Post instance to a Map<String, dynamic> for Firestore storage
  Map<String, dynamic> toMap() {
    return {
      'postId': postId,
      'uid': uid,
      'title': title,
      'description': description,
      'outfits': outfits?.map((e) => e.toJson()).toList() ?? [],
      'clothes': clothes?.map((e) => e.toJson()).toList() ?? [],
      'likes': likes?.map((e) => e.toJson()).toList() ?? [],
      'comments': comments?.map((e) => e.toJson()).toList() ?? [],
      'timestamp': timestamp?.toIso8601String(),
      'isPublic': isPublic,
    };
  }

  // ✅ Add this method inside your Post class
  factory Post.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Post(
      postId: doc.id,
      uid: data['uid'],
      title: data['title'],
      description: data['description'],
      outfits: (data['outfits'] as List<dynamic>?)
              ?.map((e) => StyledOutfit.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      clothes: (data['clothes'] as List<dynamic>?)
              ?.map((e) => Cloth.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      likes: (data['likes'] as List<dynamic>?)
              ?.map((e) => Like.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      comments: (data['comments'] as List<dynamic>?)
              ?.map((e) => Comment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      timestamp: data['timestamp'] != null
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.now(),
      isPublic: data['isPublic'] ?? false,
    );
  }
}
