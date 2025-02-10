class Comment {
  String commentId;
  String userId;
  String postId;
  String text;
  DateTime timestamp;

  Comment({
    required this.commentId,
    required this.userId,
    required this.postId,
    required this.text,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Comment.fromJson(Map<String, dynamic> json)
      : commentId = json['commentId'],
        userId = json['userId'],
        postId = json['postId'],
        text = json['text'],
        timestamp = DateTime.parse(json['timestamp']);

  Map<String, dynamic> toJson() {
    return {
      'commentId': commentId,
      'userId': userId,
      'postId': postId,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
