import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;

class StorageService {

final FirebaseStorage _firebaseStorage = FirebaseStorage.instance;

  StorageService();

  Future<String?> uploadImages({required File file, required String uid}) async {
      Reference fileRef=_firebaseStorage.ref('users/profile_pictures').child('$uid${path.extension(file.path)}');
      UploadTask task = fileRef.putFile(file);
      return task.then((p){
            if(p.state==TaskState.success){
              return fileRef.getDownloadURL();
          }
        }
      );
  }
  Future<String?> uploadImageToChat({required File file, required String chatId}) async{
    Reference fileRef= _firebaseStorage.ref('chats/$chatId').child('${DateTime.now().toIso8601String()}${path.extension(file.path)}');
    UploadTask task = fileRef.putFile(file);
    return task.then((p){
            if(p.state==TaskState.success){
              return fileRef.getDownloadURL();
          }
        }
      );
  }

  Future<String?> uploadClothImage({required File file, required String uid, required String clothType}) async {
    // Determine the storage path based on the cloth type
    String storagePath = 'users/$uid/clothes/$clothType/${DateTime.now().toIso8601String()}${path.extension(file.path)}';

    Reference fileRef = _firebaseStorage.ref(storagePath);
    UploadTask task = fileRef.putFile(file);
    
    return task.then((p) {
      if (p.state == TaskState.success) {
        return fileRef.getDownloadURL();
      }
      return null; // Return null if upload fails
    });
  }

}