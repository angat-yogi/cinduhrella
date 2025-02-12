class Cloth {
  String? clothId;
  String? storageId; // Reference to the Storage
  String? brand;
  String? size;
  String? imageUrl;
  String? description;
  String? uid;
  String? type;
  String? color;

  Cloth({
    required this.clothId,
    required this.storageId,
    required this.uid,
    required this.imageUrl,
    this.brand,
    this.size,
    this.description,
    this.type,
    this.color,
  });
  Cloth.empty()
      : clothId = null,
        storageId = null,
        uid = null,
        imageUrl =
            "https://res.cloudinary.com/hamstech/images/w_440,h_660/f_auto,q_auto/v1628494598/Hamstech%20App/Culottes/Culottes.jpg?_i=AA",
        type = null,
        brand = null,
        size = null,
        description = null,
        color = null;
  // Named constructor to initialize a Cloth instance from a JSON object
  Cloth.fromJson(Map<String, dynamic> json) {
    clothId = json['clothId'];
    storageId = json['storageId'];
    uid = json['uid'];
    brand = json['brand'];
    size = json['size'];
    imageUrl = json['imageUrl'];
    description = json['description'];
    type = json['type'];
    color = json['color'];
  }

  // Converts a Cloth instance to a JSON object for saving to Firebase
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['clothId'] = clothId;
    data['storageId'] = storageId;
    data['uid'] = uid;
    data['brand'] = brand;
    data['size'] = size;
    data['imageUrl'] = imageUrl;
    data['description'] = description;
    data['type'] = type;
    data['color'] = color;
    return data;
  }

  factory Cloth.fromMap(Map<String, dynamic> map) {
    return Cloth(
      clothId: map['clothId'],
      storageId: map['storageId'],
      uid: map['uid'],
      brand: map['brand'],
      size: map['size'],
      imageUrl: map['imageUrl'],
      description: map['description'],
      type: map['type'],
      color: map['color'],
    );
  }

  // Converts a Cloth instance to a Map<String, dynamic> for Firestore storage
  Map<String, dynamic> toMap() {
    return {
      'clothId': clothId,
      'storageId': storageId,
      'uid': uid,
      'brand': brand,
      'size': size,
      'imageUrl': imageUrl,
      'description': description,
      'type': type,
      'color': color,
    };
  }
}
