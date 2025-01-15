class Room {
  String? roomId;
  String? name;
  String? imageUrl; // Field to store the room's image URL
  String? uid; // The user ID to whom this room belongs

  Room({
    required this.roomId,
    required this.name,
    required this.uid,
    this.imageUrl,
  });

  // Named constructor to initialize a Room instance from a JSON object
  Room.fromJson(Map<String, dynamic> json) {
    roomId = json['roomId'];
    name = json['name'];
    uid = json['uid'];
    imageUrl = json['imageUrl'];
  }

  // Converts a Room instance to a JSON object for saving to Firebase
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['roomId'] = roomId;
    data['name'] = name;
    data['uid'] = uid;
    data['imageUrl'] = imageUrl;
    return data;
  }
}
