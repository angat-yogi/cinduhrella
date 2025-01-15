class Storage {
  String? storageId;
  String? name;
  String? roomId; // The room ID to which this storage belongs
  String? imageUrl; // Field to store the storage's image URL
  String? uid; // The user ID to whom this storage belongs

  Storage({
    required this.storageId,
    required this.name,
    required this.roomId,
    required this.uid,
    this.imageUrl,
  });

  // Named constructor to initialize a Storage instance from a JSON object
  Storage.fromJson(Map<String, dynamic> json) {
    storageId = json['storageId'];
    name = json['name'];
    roomId = json['roomId'];
    uid = json['uid'];
    imageUrl = json['imageUrl'];
  }

  // Converts a Storage instance to a JSON object for saving to Firebase
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['storageId'] = storageId;
    data['name'] = name;
    data['roomId'] = roomId;
    data['uid'] = uid;
    data['imageUrl'] = imageUrl;
    return data;
  }
}
