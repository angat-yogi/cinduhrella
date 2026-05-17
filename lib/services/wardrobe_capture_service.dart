import 'dart:io';

import 'package:cinduhrella/models/draft_cloth.dart';
import 'package:cinduhrella/models/wardrobe_capture_session.dart';
import 'package:cinduhrella/services/chat_service.dart';
import 'package:cinduhrella/services/database_service.dart';
import 'package:cinduhrella/services/storage_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';

class WardrobeCaptureResult {
  final WardrobeCaptureSession session;
  final List<DraftCloth> drafts;

  const WardrobeCaptureResult({
    required this.session,
    required this.drafts,
  });
}

class WardrobeCaptureService {
  WardrobeCaptureService() {
    final getIt = GetIt.instance;
    _databaseService = getIt.get<DatabaseService>();
    _storageService = getIt.get<StorageService>();
    _chatService = getIt.get<ChatService>();
  }

  late final DatabaseService _databaseService;
  late final StorageService _storageService;
  late final ChatService _chatService;

  Future<WardrobeCaptureResult> captureBatch({
    required String userId,
    required List<File> images,
  }) async {
    final sessionId =
        FirebaseFirestore.instance.collection('tmpCaptureSessions').doc().id;
    final uploadedUrls = <String>[];
    final drafts = <DraftCloth>[];

    for (final image in images) {
      final imageUrl = await _storageService.uploadCaptureImage(
        file: image,
        uid: userId,
        sessionId: sessionId,
      );

      if (imageUrl == null) {
        continue;
      }

      uploadedUrls.add(imageUrl);
      final details =
          await _chatService.getClothingDetailsFromChatGPT(imageUrl);
      final draftId =
          FirebaseFirestore.instance.collection('tmpDraftClothes').doc().id;
      final confidence = _estimateConfidence(details);

      drafts.add(
        DraftCloth(
          draftId: draftId,
          uid: userId,
          imageUrl: imageUrl,
          brand: details['brand'],
          size: details['size'],
          description: details['description'],
          type: details['type'],
          color: details['color'],
          confidence: confidence,
          status: DraftItemStatus.draftDetected,
          source: DraftItemSource.bulkPhoto,
          captureSessionId: sessionId,
          needsReview: confidence < 0.8,
          createdAt: DateTime.now(),
        ),
      );
    }

    final session = WardrobeCaptureSession(
      sessionId: sessionId,
      uid: userId,
      imageUrls: uploadedUrls,
      detectedCount: drafts.length,
      confirmedCount: 0,
      createdAt: DateTime.now(),
    );

    await _databaseService.saveWardrobeCaptureSession(userId, session);
    await _databaseService.saveDraftItems(userId, drafts);

    return WardrobeCaptureResult(session: session, drafts: drafts);
  }

  double _estimateConfidence(Map<String, String> details) {
    final keys = ['type', 'brand', 'color', 'size', 'description'];
    final filled =
        keys.where((key) => (details[key] ?? '').trim().isNotEmpty).length;
    return filled / keys.length;
  }
}
