import 'dart:io';

import 'package:cinduhrella/models/cloth.dart';
import 'package:cinduhrella/models/user_profile.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:logger/logger.dart';

class DatabaseService {
  final Logger _logger = Logger();
  final FirebaseFirestore _firebaseFirestore = FirebaseFirestore.instance;
  final FirebaseStorage _firebaseStorage = FirebaseStorage.instance;

  DatabaseService() {
    _setUpCollectionReferences();
  }

  CollectionReference? _usersCollection;

  void _setUpCollectionReferences() {
    _usersCollection = _firebaseFirestore.collection('users');
  }

  // -------------- Upload to Firebase Storage ----------------
  Future<String> uploadImage(
      String userId, File imageFile, String folder) async {
    try {
      final storageRef = _firebaseStorage.ref().child(
          'users/$userId/$folder/${DateTime.now().millisecondsSinceEpoch}');
      await storageRef.putFile(imageFile);
      return await storageRef.getDownloadURL();
    } catch (e) {
      _logger.e('Error uploading image: $e');
      rethrow;
    }
  }

  // -------------- CRUD Operations for Rooms ----------------

  Future<void> addRoom(String userId, String roomName, String imageUrl) async {
    if (imageUrl.isEmpty ||
        !(Uri.tryParse(imageUrl)?.hasAbsolutePath ?? false)) {
      _logger.e('Invalid image URL for room.');
      return;
    }
    try {
      await _firebaseFirestore
          .collection('users/$userId/rooms')
          .add({'roomName': roomName, 'imageUrl': imageUrl});
      _logger.i("Room added successfully");
    } catch (e) {
      _logger.e('Error adding room: $e');
    }
  }

  Future<void> updateRoom(
      String userId, String roomId, String roomName, String imageUrl) async {
    if (imageUrl.isEmpty ||
        !(Uri.tryParse(imageUrl)?.hasAbsolutePath ?? false)) {
      _logger.e('Invalid image URL for room.');
      return;
    }
    try {
      await _firebaseFirestore
          .collection('users/$userId/rooms')
          .doc(roomId)
          .update({'roomName': roomName, 'imageUrl': imageUrl});
      _logger.i("Room updated successfully");
    } catch (e) {
      _logger.e('Error updating room: $e');
    }
  }

  Future<void> deleteRoom(String userId, String roomId) async {
    try {
      await _firebaseFirestore
          .collection('users/$userId/rooms')
          .doc(roomId)
          .delete();
      _logger.i("Room deleted successfully");
    } catch (e) {
      _logger.e('Error deleting room: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> getRooms(String userId) {
    return _firebaseFirestore.collection('users/$userId/rooms').snapshots().map(
      (snapshot) {
        return snapshot.docs.map((doc) {
          return {'roomId': doc.id, ...doc.data()};
        }).toList();
      },
    );
  }

  // -------------- CRUD Operations for Storages ----------------

  Future<void> addStorage(
      String userId, String roomId, String storageName, String imageUrl) async {
    if (imageUrl.isEmpty ||
        !(Uri.tryParse(imageUrl)?.hasAbsolutePath ?? false)) {
      _logger.e('Invalid image URL for storage.');
      return;
    }
    try {
      await _firebaseFirestore
          .collection('users/$userId/rooms/$roomId/storages')
          .add({'storageName': storageName, 'imageUrl': imageUrl});
      _logger.i("Storage added successfully");
    } catch (e) {
      _logger.e('Error adding storage: $e');
    }
  }

  Future<void> updateStorage(String userId, String roomId, String storageId,
      String storageName, String imageUrl) async {
    if (imageUrl.isEmpty ||
        !(Uri.tryParse(imageUrl)?.hasAbsolutePath ?? false)) {
      _logger.e('Invalid image URL for storage.');
      return;
    }
    try {
      await _firebaseFirestore
          .collection('users/$userId/rooms/$roomId/storages')
          .doc(storageId)
          .update({'storageName': storageName, 'imageUrl': imageUrl});
      _logger.i("Storage updated successfully");
    } catch (e) {
      _logger.e('Error updating storage: $e');
    }
  }

  Future<void> deleteStorage(
      String userId, String roomId, String storageId) async {
    try {
      await _firebaseFirestore
          .collection('users/$userId/rooms/$roomId/storages')
          .doc(storageId)
          .delete();
      _logger.i("Storage deleted successfully");
    } catch (e) {
      _logger.e('Error deleting storage: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> getStorages(String userId, String roomId) {
    return _firebaseFirestore
        .collection('users/$userId/rooms/$roomId/storages')
        .snapshots()
        .map(
      (snapshot) {
        return snapshot.docs.map((doc) {
          return {'storageId': doc.id, ...doc.data()};
        }).toList();
      },
    );
  }

  // -------------- CRUD Operations for Clothes ----------------

  Future<void> addCloth(
      String userId, String roomId, String storageId, Cloth cloth) async {
    try {
      await _firebaseFirestore
          .collection('users/$userId/rooms/$roomId/storages/$storageId/clothes')
          .add(cloth.toJson());
      _logger.i("Cloth added successfully");
    } catch (e) {
      _logger.e('Error adding cloth: $e');
    }
  }

  Future<void> updateCloth(String userId, String roomId, String storageId,
      String clothId, Cloth cloth) async {
    try {
      await _firebaseFirestore
          .collection('users/$userId/rooms/$roomId/storages/$storageId/clothes')
          .doc(clothId)
          .update(cloth.toJson());
      _logger.i("Cloth updated successfully");
    } catch (e) {
      _logger.e('Error updating cloth: $e');
    }
  }

  Future<void> deleteCloth(
      String userId, String roomId, String storageId, String clothId) async {
    try {
      await _firebaseFirestore
          .collection('users/$userId/rooms/$roomId/storages/$storageId/clothes')
          .doc(clothId)
          .delete();
      _logger.i("Cloth deleted successfully");
    } catch (e) {
      _logger.e('Error deleting cloth: $e');
    }
  }

  Stream<List<Cloth>> getClothes(
      String userId, String roomId, String storageId) {
    return _firebaseFirestore
        .collection('users/$userId/rooms/$roomId/storages/$storageId/clothes')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Cloth.fromJson(doc.data());
      }).toList();
    });
  }

  Future<void> createUserProfile({required UserProfile userProfile}) async {
    try {
      await _usersCollection?.doc(userProfile.uid).set(userProfile.toJson());
    } catch (e) {
      _logger.e('Error creating user profile: $e');
      rethrow;
    }
  }
}
