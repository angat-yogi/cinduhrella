class Like {
  String likeId;
  String userId;
  String postId;
  DateTime timestamp;

  Like({
    required this.likeId,
    required this.userId,
    required this.postId,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Like.fromJson(Map<String, dynamic> json)
      : likeId = json['likeId'],
        userId = json['userId'],
        postId = json['postId'],
        timestamp = DateTime.parse(json['timestamp']);

  Map<String, dynamic> toJson() {
    return {
      'likeId': likeId,
      'userId': userId,
      'postId': postId,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
