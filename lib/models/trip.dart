import 'package:cloud_firestore/cloud_firestore.dart';
import 'styled_outfit.dart';
import 'cloth.dart';

class Trip {
  String? tripId;
  String tripName;
  Timestamp fromDate;
  Timestamp throughDate;
  String? imageUrl;
  List<StyledOutfit> outfits;
  List<Cloth> items;

  // Derived field: Number of days between fromDate and throughDate
  int get numberOfDays {
    DateTime from = fromDate.toDate();
    DateTime through = throughDate.toDate();
    return through.difference(from).inDays + 1;
  }

  Trip({
    this.tripId,
    required this.tripName,
    required this.fromDate,
    required this.throughDate,
    this.imageUrl,
    required this.outfits,
    required this.items,
  });

  // Convert JSON data into a Trip object
  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      tripId: json['tripId'],
      tripName: json['tripName'],
      fromDate: json['fromDate'] ?? Timestamp.now(),
      throughDate: json['throughDate'] ?? Timestamp.now(),
      imageUrl: json['imageUrl'],
      outfits: (json['outfits'] as List<dynamic>)
          .map((item) => StyledOutfit.fromJson(item))
          .toList(),
      items: (json['items'] as List<dynamic>)
          .map((item) => Cloth.fromJson(item))
          .toList(),
    );
  }

  // Convert Trip object into JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'tripId': tripId,
      'tripName': tripName,
      'fromDate': fromDate,
      'throughDate': throughDate,
      'imageUrl': imageUrl,
      'outfits': outfits.map((outfit) => outfit.toJson()).toList(),
      'items': items.map((cloth) => cloth.toJson()).toList(),
    };
  }

  // Convert Firestore document to Trip object
  factory Trip.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return Trip(
      tripId: doc.id,
      tripName: data['tripName'],
      fromDate: data['fromDate'] ?? Timestamp.now(),
      throughDate: data['throughDate'] ?? Timestamp.now(),
      imageUrl: data['imageUrl'],
      outfits: (data['outfits'] as List<dynamic>)
          .map((item) => StyledOutfit.fromJson(item))
          .toList(),
      items: (data['items'] as List<dynamic>)
          .map((item) => Cloth.fromJson(item))
          .toList(),
    );
  }
}
