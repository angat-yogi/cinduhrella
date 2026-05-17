import 'dart:convert';
import 'dart:io';

import 'package:cinduhrella/models/closet_scan_detection.dart';
import 'package:cinduhrella/services/database_service.dart';
import 'package:cinduhrella/services/storage_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:get_it/get_it.dart';

class ClosetScannerService {
  ClosetScannerService() {
    final getIt = GetIt.instance;
    _storageService = getIt.get<StorageService>();
    _databaseService = getIt.get<DatabaseService>();
  }

  late final StorageService _storageService;
  late final DatabaseService _databaseService;

  String get _baseUrl {
    final configured = dotenv.env['CLOSET_SCANNER_BACKEND_URL'] ?? '';
    if (configured.isNotEmpty) {
      return configured;
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://127.0.0.1:8000';
  }

  Future<List<ClosetScanDetection>> detectClothes(File imageFile) async {
    final uri = Uri.parse('$_baseUrl/detect-clothes');
    final request = http.MultipartRequest('POST', uri)
      ..files.add(
        await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
          filename: path.basename(imageFile.path),
        ),
      );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        'Closet scanner request failed: ${response.statusCode} ${response.body}',
      );
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final detections = List<Map<String, dynamic>>.from(
      payload['detections'] ?? const [],
    );

    return detections.asMap().entries.map((entry) {
      final data = entry.value;
      final suffix = DateTime.now().microsecondsSinceEpoch + entry.key;
      return ClosetScanDetection.fromJson(data, tempId: 'scan_$suffix');
    }).toList();
  }

  Future<void> saveApprovedItems({
    required String userId,
    required List<ClosetScanDetection> detections,
  }) async {
    for (final detection in detections.where((item) => item.approved)) {
      final itemId =
          FirebaseFirestore.instance.collection('tmpClosetItems').doc().id;
      final imageUrl = await _storageService.uploadClosetItemImageBytes(
        bytes: detection.cropBytes,
        uid: userId,
        itemId: itemId,
      );
      if (imageUrl == null) {
        continue;
      }

      await _databaseService.saveClosetItem(
        userId: userId,
        itemId: itemId,
        data: {
          'userId': userId,
          'rawLabel': detection.rawLabel,
          'normalizedCategory': detection.normalizedCategory,
          'displayLabel': detection.displayLabel,
          'colors': detection.colors,
          'brand': null,
          'confidence': detection.confidence,
          'imageUrl': imageUrl,
          'bbox': detection.bbox,
          'source': 'closet_camera_scan',
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        },
      );
    }
  }
}
