import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:path/path.dart' as path;
import 'package:logger/logger.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class StorageService {
  final FirebaseStorage _firebaseStorage = FirebaseStorage.instance;
  final Logger _logger = Logger();

  StorageService();

  String get _backgroundRemovalEndpoint {
    final configured = dotenv.env['CLOSET_SCANNER_BACKEND_URL'] ?? '';
    final String baseUrl;
    if (configured.isNotEmpty) {
      baseUrl = configured;
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      baseUrl = 'http://10.0.2.2:8000';
    } else {
      baseUrl = 'http://127.0.0.1:8000';
    }
    return '${baseUrl.replaceFirst(RegExp(r'/$'), '')}/remove-background';
  }

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
      } else if (pathType == 'closet') {
        folderPath = 'users/$uid/closetItems/$fileName';
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
      _logger.e('Upload Error: $e');
    }
    return null; // Upload failed
  }

  Future<File?> removeBackground(File file) async {
    final inputBytes = await file.readAsBytes();
    final outputBytes = await removeBackgroundBytes(
      inputBytes,
      fileName: path.basename(file.path),
    );
    if (outputBytes == null) {
      return null;
    }

    final tempDir = await getTemporaryDirectory();
    final outputName = '${path.basenameWithoutExtension(file.path)}_nobg.png';
    final tempFile = File(path.join(tempDir.path, outputName));
    await tempFile.writeAsBytes(outputBytes, flush: true);
    return tempFile;
  }

  Future<Uint8List?> removeBackgroundBytes(
    Uint8List bytes, {
    required String fileName,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse(_backgroundRemovalEndpoint),
      )..files.add(
          http.MultipartFile.fromBytes(
            'file',
            bytes,
            filename: fileName,
          ),
        );

      final response = await request.send().timeout(
            const Duration(minutes: 2),
          );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return Uint8List.fromList(await response.stream.toBytes());
      }

      final responseBody = await response.stream.bytesToString();
      _logger.e(
        'Local background removal failed: '
        '${response.statusCode} $responseBody',
      );
    } catch (error, stackTrace) {
      _logger.e(
        'Local background removal request failed. Using the original image.',
        error: error,
        stackTrace: stackTrace,
      );
    }
    return null;
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

  Future<String?> uploadCaptureImage({
    required File file,
    required String uid,
    required String sessionId,
  }) async {
    try {
      final processedFile = await removeBackground(file);
      final uploadFile = processedFile ?? file;
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}${path.extension(uploadFile.path)}';
      final fileRef = _firebaseStorage
          .ref('users/$uid/captureSessions/$sessionId/$fileName');
      final snapshot = await fileRef.putFile(uploadFile);
      if (snapshot.state == TaskState.success) {
        return await fileRef.getDownloadURL();
      }
    } catch (e) {
      _logger.e('Capture upload failed: $e');
    }
    return null;
  }

  Future<String?> uploadBodyProfileImage({
    required File file,
    required String uid,
    required String bodyProfileId,
  }) async {
    try {
      final processedFile = await removeBackground(file);
      final uploadFile = processedFile ?? file;
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}${path.extension(uploadFile.path)}';
      final fileRef = _firebaseStorage
          .ref('users/$uid/bodyProfiles/$bodyProfileId/$fileName');
      final snapshot = await fileRef.putFile(uploadFile);
      if (snapshot.state == TaskState.success) {
        return await fileRef.getDownloadURL();
      }
    } catch (e) {
      _logger.e('Body profile upload failed: $e');
    }
    return null;
  }

  Future<String?> uploadOwnerReferenceImage({
    required File file,
    required String uid,
  }) async {
    try {
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}${path.extension(file.path)}';
      final fileRef =
          _firebaseStorage.ref('users/$uid/photoImportReferences/$fileName');
      final snapshot = await fileRef.putFile(file);
      if (snapshot.state == TaskState.success) {
        return await fileRef.getDownloadURL();
      }
    } catch (e) {
      _logger.e('Owner reference upload failed: $e');
    }
    return null;
  }

  Future<String?> uploadGarmentAssetImage({
    required File file,
    required String uid,
    required String garmentAssetId,
  }) async {
    try {
      final processedFile = await removeBackground(file);
      final uploadFile = processedFile ?? file;
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}${path.extension(uploadFile.path)}';
      final fileRef = _firebaseStorage
          .ref('users/$uid/garmentAssets/$garmentAssetId/$fileName');
      final snapshot = await fileRef.putFile(uploadFile);
      if (snapshot.state == TaskState.success) {
        return await fileRef.getDownloadURL();
      }
    } catch (e) {
      _logger.e('Garment asset upload failed: $e');
    }
    return null;
  }

  Future<String?> uploadClosetItemImageBytes({
    required Uint8List bytes,
    required String uid,
    required String itemId,
  }) async {
    try {
      final processedBytes = await removeBackgroundBytes(
        bytes,
        fileName: 'closet-item-$itemId.jpg',
      );
      final fileRef =
          _firebaseStorage.ref('users/$uid/closetItems/$itemId/crop.png');
      final snapshot = await fileRef.putData(
        processedBytes ?? bytes,
        SettableMetadata(
          contentType: processedBytes != null ? 'image/png' : 'image/jpeg',
        ),
      );
      if (snapshot.state == TaskState.success) {
        return await fileRef.getDownloadURL();
      }
    } catch (e) {
      _logger.e('Closet item upload failed: $e');
    }
    return null;
  }

  Future<String?> uploadDraftItemImageBytes({
    required Uint8List bytes,
    required String uid,
    required String draftId,
  }) async {
    try {
      final processedBytes = await removeBackgroundBytes(
        bytes,
        fileName: 'draft-item-$draftId.png',
      );
      final outputBytes = processedBytes ?? bytes;
      final fileRef =
          _firebaseStorage.ref('users/$uid/draftItems/$draftId/crop.png');
      final snapshot = await fileRef.putData(
        outputBytes,
        SettableMetadata(
          contentType: 'image/png',
        ),
      );
      if (snapshot.state == TaskState.success) {
        return await fileRef.getDownloadURL();
      }
    } catch (e) {
      _logger.e('Draft item upload failed: $e');
    }
    return null;
  }
}
