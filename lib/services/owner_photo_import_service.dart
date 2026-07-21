import 'dart:io';
import 'dart:async';

import 'package:cinduhrella/models/draft_cloth.dart';
import 'package:cinduhrella/models/photo_import_job.dart';
import 'package:cinduhrella/models/photo_import_preferences.dart';
import 'package:cinduhrella/models/user_profile.dart';
import 'package:cinduhrella/models/wardrobe_capture_session.dart';
import 'package:cinduhrella/services/chat_service.dart';
import 'package:cinduhrella/services/database_service.dart';
import 'package:cinduhrella/services/storage_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';

class OwnerPhotoImportResult {
  final WardrobeCaptureSession session;
  final List<DraftCloth> drafts;

  const OwnerPhotoImportResult({
    required this.session,
    required this.drafts,
  });
}

class OwnerPhotoImportService {
  OwnerPhotoImportService() {
    final getIt = GetIt.instance;
    _databaseService = getIt.get<DatabaseService>();
    _storageService = getIt.get<StorageService>();
    _chatService = getIt.get<ChatService>();
  }

  late final DatabaseService _databaseService;
  late final StorageService _storageService;
  late final ChatService _chatService;

  Future<PhotoImportJob> queueOwnerPhotoImport({
    required UserProfile profile,
    required List<File> images,
  }) async {
    final userId = profile.uid!;
    final now = DateTime.now();
    final jobId =
        FirebaseFirestore.instance.collection('tmpOwnerPhotoJobs').doc().id;
    final job = PhotoImportJob(
      jobId: jobId,
      userId: userId,
      status: PhotoImportJobStatus.queued,
      mode: PhotoImportJobMode.ownerLibrarySelection,
      totalImages: images.length,
      processedImages: 0,
      createdDrafts: 0,
      title: 'Import from my photos',
      createdAt: now,
      updatedAt: now,
    );
    await _databaseService.savePhotoImportJob(userId, job);
    unawaited(_runQueuedImport(job: job, profile: profile, images: images));
    return job;
  }

  Future<void> updatePreferences({
    required UserProfile profile,
    required PhotoImportPreferences preferences,
  }) async {
    final updated = UserProfile(
      uid: profile.uid,
      fullName: profile.fullName,
      profilePictureUrl: profile.profilePictureUrl,
      userName: profile.userName,
      followingCount: profile.followingCount,
      followersCount: profile.followersCount,
      postCount: profile.postCount,
      following: profile.following,
      followers: profile.followers,
      posts: profile.posts,
      bodyMeasurements: profile.bodyMeasurements,
      stylePreferences: profile.stylePreferences,
      photoImportPreferences: preferences,
    );
    await _databaseService.updateUserStyleProfile(profile.uid!, updated);
  }

  Future<OwnerPhotoImportResult> importFromSelectedPhotos({
    required UserProfile profile,
    required List<File> images,
  }) async {
    final userId = profile.uid!;
    final sessionId =
        FirebaseFirestore.instance.collection('tmpOwnerPhotoImports').doc().id;
    final uploadedUrls = <String>[];
    final drafts = <DraftCloth>[];
    final preferences = profile.photoImportPreferences;
    final ownerHint = [
      profile.fullName,
      profile.userName,
      preferences.ownerIdentityHint,
      ...preferences.ownerReferenceImageUrls.take(2),
    ].whereType<String>().where((value) => value.trim().isNotEmpty).join(' | ');

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
      final details = await _chatService.getOwnerPhotoClothingDetails(
        imageUrl,
        ownerHint: ownerHint,
        ownerOnlyMode: preferences.ownerOnlyImportEnabled,
      );
      final draftId =
          FirebaseFirestore.instance.collection('tmpOwnerPhotoDrafts').doc().id;
      final ownerMatchConfidence =
          double.tryParse(details['ownerMatchConfidence'] ?? '') ?? 0;
      final confidence = _estimateConfidence(details, ownerMatchConfidence);

      if ((details['type'] ?? '').trim().isEmpty &&
          ownerMatchConfidence < 0.55) {
        continue;
      }

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
          ownerMatchConfidence: ownerMatchConfidence,
          status: DraftItemStatus.draftDetected,
          source: DraftItemSource.ownerPhotoLibrary,
          captureSessionId: sessionId,
          needsReview: confidence < 0.85 || ownerMatchConfidence < 0.8,
          createdAt: DateTime.now(),
          importContext:
              details['ownerReason'] ?? 'Imported from personal photos',
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
      importMode: CaptureImportMode.ownerLibraryPhotos,
      consentedOwnerOnlyImport: preferences.consentGranted,
    );

    await _databaseService.saveWardrobeCaptureSession(userId, session);
    await _databaseService.saveDraftItems(userId, drafts);

    return OwnerPhotoImportResult(session: session, drafts: drafts);
  }

  double _estimateConfidence(
    Map<String, String> details,
    double ownerMatchConfidence,
  ) {
    final keys = ['type', 'brand', 'color', 'size', 'description'];
    final filled =
        keys.where((key) => (details[key] ?? '').trim().isNotEmpty).length;
    return ((filled / keys.length) * 0.65) + (ownerMatchConfidence * 0.35);
  }

  Future<void> _runQueuedImport({
    required PhotoImportJob job,
    required UserProfile profile,
    required List<File> images,
  }) async {
    await _databaseService.savePhotoImportJob(
      job.userId,
      job.copyWith(
        status: PhotoImportJobStatus.processing,
        updatedAt: DateTime.now(),
      ),
    );

    try {
      final result = await importFromSelectedPhotos(
        profile: profile,
        images: images,
      );
      await _databaseService.savePhotoImportJob(
        job.userId,
        job.copyWith(
          status: PhotoImportJobStatus.completed,
          processedImages: images.length,
          createdDrafts: result.drafts.length,
          sessionId: result.session.sessionId,
          updatedAt: DateTime.now(),
        ),
      );
    } catch (e) {
      await _databaseService.savePhotoImportJob(
        job.userId,
        job.copyWith(
          status: PhotoImportJobStatus.failed,
          errorMessage: e.toString(),
          updatedAt: DateTime.now(),
        ),
      );
    }
  }
}
