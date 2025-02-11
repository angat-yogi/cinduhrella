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
        posts = List<String>.from(json['posts'] ?? []); // ✅ Convert posts

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
    };
  }
}
