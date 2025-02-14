import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import 'package:logger/logger.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class StorageService {
  final FirebaseStorage _firebaseStorage = FirebaseStorage.instance;
  final Logger _logger = Logger();

  StorageService();

  Future<String?> uploadImages(
      {required File file, required String uid}) async {
    // Reference fileRef = _firebaseStorage
    //     .ref('users/profile_pictures')
    //     .child('$uid${path.extension(file.path)}');
    Reference fileRef = _firebaseStorage
        .ref('users/$uid/profile_picture') // ✅ Correct path
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
      String? roomId,
      String? storageId}) async {
    try {
      // Remove background from image before uploading
      File? processedFile = await removeBackground(file);

      // If background removal fails, fallback to original file
      File uploadFile = processedFile ?? file;

      String fileName =
          '${DateTime.now().millisecondsSinceEpoch}${path.extension(uploadFile.path)}';

      // Determine the correct path for the image
      String folderPath;
      if (pathType == 'room') {
        folderPath = 'users/$uid/rooms/$fileName';
      } else if (pathType == 'storage' && roomId != null) {
        folderPath = 'users/$uid/rooms/$roomId/storages/$fileName';
      } else if (pathType == 'item' && roomId != null && storageId != null) {
        folderPath =
            'users/$uid/rooms/$roomId/storages/$storageId/items/$fileName';
      } else if (pathType == 'unassigned') {
        folderPath = 'users/$uid/unassigned/$fileName';
      } else if (pathType == 'trips') {
        folderPath = 'users/$uid/trips/$fileName';
      } else {
        throw Exception(
            "Invalid pathType or missing parameters.\npathType: $pathType, roomId: $roomId, storageId: $storageId, userId: $uid");
      }

      Reference fileRef = _firebaseStorage.ref(folderPath);
      UploadTask task = fileRef.putFile(uploadFile);
      TaskSnapshot snapshot = await task;

      if (snapshot.state == TaskState.success) {
        return await fileRef.getDownloadURL(); // Return Firebase Storage URL
      }
    } catch (e) {
      print("Upload Error: $e");
    }
    return null; // Upload failed
  }

  Future<File?> removeBackground(File file) async {
    final apiKey = "ZM9TtVdxwdpjFi9aGSLubs5h";
    final url = "https://api.remove.bg/v1.0/removebg";

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
      final tempFile = File(
          '${(await getTemporaryDirectory()).path}/${path.basename(file.path)}');
      await tempFile.writeAsBytes(bytes);
      return tempFile; // Return the processed image file
    } else {
      _logger.e('Failed to remove background: ${response.reasonPhrase}');
      return null; // Return null if the request fails
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
