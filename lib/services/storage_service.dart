import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

class StorageService {
  final FirebaseStorage _firebaseStorage = FirebaseStorage.instance;

  StorageService();

  Future<String?> uploadImages(
      {required File file, required String uid}) async {
    Reference fileRef = _firebaseStorage
        .ref('users/profile_pictures')
        .child('$uid${path.extension(file.path)}');
    UploadTask task = fileRef.putFile(file);
    return task.then((p) {
      if (p.state == TaskState.success) {
        return fileRef.getDownloadURL();
      }
      return null;
    });
  }

  Future<String?> uploadImage(
      {required File file,
      required String uid,
      required String pathType,
      String? roomId, // Only required if uploading a storage image
      String? storageId}) async {
    try {
      String fileName =
          '${DateTime.now().millisecondsSinceEpoch}${path.extension(file.path)}';

      // Determine the correct path for the image
      String folderPath;
      if (pathType == 'room') {
        folderPath = 'users/$uid/rooms/$fileName'; // Room image
      } else if (pathType == 'storage' && roomId != null) {
        folderPath =
            'users/$uid/rooms/$roomId/storages/$fileName'; // Storage image inside room
      } else if (pathType == 'item' && roomId != null && storageId != null) {
        folderPath =
            'users/$uid/rooms/$roomId/storages/$storageId/items/$fileName'; // Item inside storage
      } else {
        throw Exception(
            "Invalid pathType or missing parameters.\npathType: $pathType, roomId: $roomId, storageId: $storageId, userId: $uid");
      }

      Reference fileRef = _firebaseStorage.ref(folderPath);
      UploadTask task = fileRef.putFile(file);
      TaskSnapshot snapshot = await task;

      if (snapshot.state == TaskState.success) {
        return await fileRef.getDownloadURL(); // Return Firebase Storage URL
      }
    } catch (e) {
      // ignore: avoid_print
      print("Upload Error: $e");
    }
    return null; // Upload failed
  }

  Future<String?> uploadImageToChat(
      {required File file, required String chatId}) async {
    Reference fileRef = _firebaseStorage.ref('chats/$chatId').child(
        '${DateTime.now().toIso8601String()}${path.extension(file.path)}');
    UploadTask task = fileRef.putFile(file);
    return task.then((p) {
      if (p.state == TaskState.success) {
        return fileRef.getDownloadURL();
      }
      return null;
    });
  }
}
