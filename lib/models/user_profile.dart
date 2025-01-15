class UserProfile {
  String? uid;
  String? fullName;
  String? userName;
  String? profilePictureUrl;

  UserProfile(
      {required this.uid,
      required this.fullName,
      required this.profilePictureUrl,
      required this.userName});

  UserProfile.fromJson(Map<String, dynamic> json) {
    uid = json['uid'];
    userName = json['userName'];
    fullName = json['fullName'];
    profilePictureUrl = json['profilePictureUrl'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['uid'] = uid;
    data['userName'] = userName;
    data['fullName'] = fullName;
    data['profilePictureUrl'] = profilePictureUrl;
    return data;
  }
}
