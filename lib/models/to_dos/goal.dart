class Goal {
  String? id;
  String name;
  double progress;
  List<String> taskIds; // Store task references (IDs)
  String? wishlistItemId;

  Goal(
      {this.id,
      required this.name,
      required this.progress,
      this.taskIds = const [],
      this.wishlistItemId});

  Goal.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        name = json['name'],
        progress = (json['progress'] is int)
            ? (json['progress'] as int).toDouble()
            : json['progress'] as double,
        taskIds = List<String>.from(json['taskIds'] ?? []),
        wishlistItemId = json['wishlistItemId'];
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'progress': progress,
      'taskIds': taskIds,
      'wishlistItemId': wishlistItemId,
    };
  }
}
