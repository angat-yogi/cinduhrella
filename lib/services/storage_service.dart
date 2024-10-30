import 'dart:io';
import 'package:cinduhrella/config.dart';
import 'package:http/http.dart' as http;

import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

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

Future<File?> removeBackground(File file) async {
  const apiKey = Config.removeBgApiKey;
  const url = Config.url;

  // Prepare the request
  var request = http.MultipartRequest('POST', Uri.parse(url))
    ..headers['X-Api-Key'] = apiKey
    ..files.add(await http.MultipartFile.fromPath(
      'image_file',
      file.path,
    ));

  // Send the request
  var response = await request.send();
  if (response.statusCode == 200) {
    // Get the response bytes
    var bytes = await response.stream.toBytes();
    
    // Create a temporary file for the processed image
    final tempFile = File('${(await getTemporaryDirectory()).path}/${path.basename(file.path)}');
    await tempFile.writeAsBytes(bytes);
    return tempFile; // Return the processed image file
  } else {
    print('Failed to remove background: ${response.reasonPhrase}');
    return null; // Return null if the request fails
  }
}

void uploadImage(String uid, String clothType) async {
  // Pick an image from the gallery or camera
  final picker = ImagePicker();
  final pickedFile = await picker.pickImage(source: ImageSource.gallery);
  
  if (pickedFile != null) {
    File file = File(pickedFile.path);
    String? downloadUrl = await uploadClothImage(file: file, uid: uid, clothType: clothType);
    
    if (downloadUrl != null) {
      print('Uploaded image URL: $downloadUrl');
    } else {
      print('Failed to upload image');
    }
  }
}


  Future<String?> uploadClothImage({
  required File file,
  required String uid,
  required String clothType,
}) async {
  // Remove the background from the image
  File? processedFile = await removeBackground(file);
  if (processedFile == null) {
    print('Background removal failed');
    return null; // Handle the failure case
  }

  // Determine the storage path based on the cloth type
  String storagePath = 'users/$uid/clothes/$clothType/${DateTime.now().toIso8601String()}${path.extension(processedFile.path)}';

  Reference fileRef = FirebaseStorage.instance.ref(storagePath);
  UploadTask task = fileRef.putFile(processedFile);

  return task.then((p) {
    if (p.state == TaskState.success) {
      return fileRef.getDownloadURL();
    }
    return null; // Return null if upload fails
  });
}


}