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

  Future<String?> uploadRoomImages(
      {required File file, required String uid}) async {
    try {
      String fileName =
          '${DateTime.now().millisecondsSinceEpoch}${path.extension(file.path)}';
      Reference fileRef = _firebaseStorage.ref('users/$uid/rooms/$fileName');

      UploadTask task = fileRef.putFile(file);
      TaskSnapshot snapshot = await task;

      if (snapshot.state == TaskState.success) {
        return await fileRef.getDownloadURL(); // Return Firebase Storage URL
      } else {
        return null; // Upload failed
      }
    } catch (e) {
      print("Upload Error: $e");
      return null;
    }
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
