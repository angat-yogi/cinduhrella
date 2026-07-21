import 'package:cinduhrella/models/body_measurements.dart';
import 'package:cinduhrella/models/photo_import_preferences.dart';

class UserProfile {
  String? uid;
  String? fullName;
  String? userName;
  String? profilePictureUrl;
  int followingCount;
  int followersCount;
  int postCount;
  List<String> following;
  List<String> followers;
  List<String> posts; // ✅ List to store post IDs
  BodyMeasurements bodyMeasurements;
  List<String> stylePreferences;
  PhotoImportPreferences photoImportPreferences;

  UserProfile({
    required this.uid,
    required this.fullName,
    required this.profilePictureUrl,
    required this.userName,
    this.followingCount = 0,
    this.followersCount = 0,
    this.postCount = 0,
    this.following = const [],
    this.followers = const [],
    this.posts = const [], // ✅ Initialize empty list
    this.bodyMeasurements = const BodyMeasurements(),
    this.stylePreferences = const [],
    this.photoImportPreferences = const PhotoImportPreferences(),
  });

  UserProfile.fromJson(Map<String, dynamic> json)
      : uid = json['uid'],
        userName = json['userName'],
        fullName = json['fullName'],
        profilePictureUrl = json['profilePictureUrl'],
        followingCount = json['followingCount'] ?? 0,
        followersCount = json['followersCount'] ?? 0,
        postCount = json['postCount'] ?? 0,
        following = List<String>.from(json['following'] ?? []),
        followers = List<String>.from(json['followers'] ?? []),
        posts = List<String>.from(json['posts'] ?? []),
        bodyMeasurements = BodyMeasurements.fromJson(
          json['bodyMeasurements'] as Map<String, dynamic>?,
        ),
        stylePreferences = List<String>.from(json['stylePreferences'] ?? []),
        photoImportPreferences = PhotoImportPreferences.fromJson(
          json['photoImportPreferences'] as Map<String, dynamic>?,
        );

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'userName': userName,
      'fullName': fullName,
      'profilePictureUrl': profilePictureUrl,
      'followingCount': followingCount,
      'followersCount': followersCount,
      'postCount': postCount,
      'following': following,
      'followers': followers,
      'posts': posts, // ✅ Save posts list
      'bodyMeasurements': bodyMeasurements.toJson(),
      'stylePreferences': stylePreferences,
      'photoImportPreferences': photoImportPreferences.toJson(),
    };
  }
}
