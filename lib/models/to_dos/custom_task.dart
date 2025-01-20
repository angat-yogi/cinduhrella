class CustomTask {
  String? id;
  String name;
  bool completed;
  String? goalId; // ID of the associated Goal (if any)

  CustomTask(
      {this.id, required this.name, required this.completed, this.goalId});

  CustomTask.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        name = json['name'],
        completed = json['completed'],
        goalId = json['goalId'];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'completed': completed,
      'goalId': goalId,
    };
  }
}
