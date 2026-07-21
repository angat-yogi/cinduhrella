import 'dart:io';

import 'package:cinduhrella/models/draft_cloth.dart';
import 'package:cinduhrella/models/wardrobe_capture_session.dart';
import 'package:cinduhrella/services/database_service.dart';
import 'package:cinduhrella/services/garment_extraction_service.dart';
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
    _garmentExtractionService = getIt.get<GarmentExtractionService>();
  }

  late final DatabaseService _databaseService;
  late final StorageService _storageService;
  late final GarmentExtractionService _garmentExtractionService;

  Future<WardrobeCaptureResult> captureBatch({
    required String userId,
    required List<File> images,
  }) async {
    final sessionId =
        FirebaseFirestore.instance.collection('tmpCaptureSessions').doc().id;
    final uploadedUrls = <String>[];
    final drafts = <DraftCloth>[];

    for (final image in images) {
      final garments = await _garmentExtractionService.extractGarments(image);
      final imageUrl = await _storageService.uploadCaptureImage(
        file: image,
        uid: userId,
        sessionId: sessionId,
      );

      if (imageUrl != null) {
        uploadedUrls.add(imageUrl);
      }

      for (final garment in garments) {
        final draftId =
            FirebaseFirestore.instance.collection('tmpDraftClothes').doc().id;
        final draftImageUrl = await _storageService.uploadDraftItemImageBytes(
          bytes: garment.cropBytes,
          uid: userId,
          draftId: draftId,
        );
        if (draftImageUrl == null) {
          continue;
        }

        drafts.add(
          DraftCloth(
            draftId: draftId,
            uid: userId,
            imageUrl: draftImageUrl,
            brand: null,
            size: null,
            description: garment.displayLabel,
            type: garment.type,
            color: garment.colors.isEmpty ? null : garment.colors.first,
            confidence: garment.confidence,
            status: DraftItemStatus.draftDetected,
            source: DraftItemSource.bulkPhoto,
            captureSessionId: sessionId,
            needsReview: true,
            createdAt: DateTime.now(),
            importContext:
                'Extracted from a wardrobe photo as ${garment.parserLabel}.',
          ),
        );
      }
    }

    final session = WardrobeCaptureSession(
      sessionId: sessionId,
      uid: userId,
      imageUrls: uploadedUrls,
      detectedCount: drafts.length,
      confirmedCount: 0,
      createdAt: DateTime.now(),
      importMode: CaptureImportMode.wardrobePhotos,
    );

    await _databaseService.saveWardrobeCaptureSession(userId, session);
    await _databaseService.saveDraftItems(userId, drafts);

    return WardrobeCaptureResult(session: session, drafts: drafts);
  }
}
