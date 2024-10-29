class Cloth {
  String? clothId;
  String? brand;
  String? size;
  String? imageUrl;
  String? description;
  String? uid;
  String? type;

  Cloth({
    required this.clothId,
    required this.uid,
    required this.imageUrl,
    this.brand,
    this.size,
    this.description,
    this.type,
  });

  // Named constructor to initialize a Cloth instance from a JSON object
  Cloth.fromJson(Map<String, dynamic> json) {
    clothId = json['clothId'];
    uid = json['uid'];
    brand = json['brand'];
    size = json['size'];
    imageUrl = json['imageUrl'];
    description = json['description'];
    type = json['type'];
  }

  // Converts a Cloth instance to a JSON object for saving to Firebase
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['clothId'] = clothId;
    data['uid'] = uid;
    data['brand'] = brand;
    data['size'] = size;
    data['imageUrl'] = imageUrl;
    data['description'] = description;
    data['type'] = type;
    return data;
  }
}
