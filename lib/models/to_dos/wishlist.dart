class Wishlist {
  String? id;
  String name;
  String imageUrl;
  int pointsNeeded;

  Wishlist(
      {this.id,
      required this.name,
      required this.imageUrl,
      required this.pointsNeeded});

  Wishlist.fromJson(Map<String, dynamic> json)
      : id = json['id'],
        name = json['name'],
        imageUrl = json['imageUrl'],
        pointsNeeded = json['pointsNeeded'];

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'pointsNeeded': pointsNeeded,
    };
  }
}
