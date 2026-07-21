import 'dart:io';
import 'dart:async';

import 'package:cinduhrella/models/draft_cloth.dart';
import 'package:cinduhrella/models/photo_import_job.dart';
import 'package:cinduhrella/models/photo_import_preferences.dart';
import 'package:cinduhrella/models/user_profile.dart';
import 'package:cinduhrella/models/wardrobe_capture_session.dart';
import 'package:cinduhrella/services/chat_service.dart';
import 'package:cinduhrella/services/database_service.dart';
import 'package:cinduhrella/services/media_service.dart';
import 'package:cinduhrella/services/storage_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';

class OwnerPhotoImportResult {
  final WardrobeCaptureSession session;
  final List<DraftCloth> drafts;
  final int processedImages;

  const OwnerPhotoImportResult({
    required this.session,
    required this.drafts,
    required this.processedImages,
  });
}

class OwnerPhotoImportService {
  OwnerPhotoImportService() {
    final getIt = GetIt.instance;
    _databaseService = getIt.get<DatabaseService>();
    _storageService = getIt.get<StorageService>();
    _chatService = getIt.get<ChatService>();
    _mediaService = getIt.get<MediaService>();
  }

  late final DatabaseService _databaseService;
  late final StorageService _storageService;
  late final ChatService _chatService;
  late final MediaService _mediaService;

  Future<PhotoImportJob> queueOwnerPhotoImport({
    required UserProfile profile,
    required List<File> images,
    PhotoImportJobMode mode = PhotoImportJobMode.ownerLibrarySelection,
    String? title,
  }) async {
    final userId = profile.uid!;
    final now = DateTime.now();
    final jobId =
        FirebaseFirestore.instance.collection('tmpOwnerPhotoJobs').doc().id;
    final job = PhotoImportJob(
      jobId: jobId,
      userId: userId,
      status: PhotoImportJobStatus.queued,
      mode: mode,
      totalImages: images.length,
      processedImages: 0,
      createdDrafts: 0,
      title: title ?? 'Import from my photos',
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

  Future<PhotoImportJob?> syncSelectedCollectionIfNeeded({
    required UserProfile profile,
    bool force = false,
    int limit = 24,
  }) async {
    final preferences = profile.photoImportPreferences;
    final userId = profile.uid!;

    if (!preferences.consentGranted ||
        !preferences.collectionAutoSyncEnabled ||
        preferences.sourceCollectionId.trim().isEmpty) {
      return null;
    }

    final activeJobs = await _databaseService.getPhotoImportJobs(userId);
    final hasActiveCollectionSync = activeJobs.any(
      (job) =>
          (job.status == PhotoImportJobStatus.queued ||
              job.status == PhotoImportJobStatus.processing) &&
          job.mode == PhotoImportJobMode.ownerLibraryAutoScan,
    );
    if (hasActiveCollectionSync) {
      return null;
    }

    final lastSyncAt = preferences.lastCollectionSyncAt;
    if (!force &&
        lastSyncAt != null &&
        DateTime.now().difference(lastSyncAt) < const Duration(minutes: 10)) {
      return null;
    }

    final assets = await _mediaService.getImagesFromCollection(
      collectionId: preferences.sourceCollectionId,
      limit: limit,
      excludeAssetIds: preferences.processedSourceAssetIds.toSet(),
    );
    if (assets.isEmpty) {
      await updatePreferences(
        profile: profile,
        preferences: preferences.copyWith(
          lastCollectionSyncAt: DateTime.now(),
        ),
      );
      return null;
    }

    final refreshedPreferences = preferences.copyWith(
      lastCollectionSyncAt: DateTime.now(),
      processedSourceAssetIds: [
        ...assets.map((asset) => asset.assetId),
        ...preferences.processedSourceAssetIds,
      ].take(300).toList(),
    );
    await updatePreferences(
      profile: profile,
      preferences: refreshedPreferences,
    );

    final refreshedProfile = UserProfile(
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
      photoImportPreferences: refreshedPreferences,
    );

    return queueOwnerPhotoImport(
      profile: refreshedProfile,
      images: assets.map((asset) => asset.file).toList(growable: false),
      mode: PhotoImportJobMode.ownerLibraryAutoScan,
      title: 'Sync ${preferences.sourceCollectionName.isEmpty ? "selected collection" : preferences.sourceCollectionName}',
    );
  }

  Future<OwnerPhotoImportResult> importFromSelectedPhotos({
    required UserProfile profile,
    required List<File> images,
    Future<bool> Function(int processedCount)? shouldContinue,
    Future<void> Function(int processedCount, int createdDrafts)?
        onProgressChanged,
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

    var processedCount = 0;

    for (final image in images) {
      if (shouldContinue != null) {
        final continueImport = await shouldContinue(processedCount);
        if (!continueImport) {
          break;
        }
      }

      final imageUrl = await _storageService.uploadCaptureImage(
        file: image,
        uid: userId,
        sessionId: sessionId,
      );

      processedCount += 1;

      if (imageUrl == null) {
        if (onProgressChanged != null) {
          await onProgressChanged(processedCount, drafts.length);
        }
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
        if (onProgressChanged != null) {
          await onProgressChanged(processedCount, drafts.length);
        }
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

      if (onProgressChanged != null) {
        await onProgressChanged(processedCount, drafts.length);
      }
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

    return OwnerPhotoImportResult(
      session: session,
      drafts: drafts,
      processedImages: processedCount,
    );
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
        shouldContinue: (processedCount) async {
          final currentJob = await _databaseService.getPhotoImportJob(
            job.userId,
            job.jobId,
          );
          return currentJob?.status != PhotoImportJobStatus.cancelled;
        },
        onProgressChanged: (processedCount, createdDrafts) async {
          final currentJob = await _databaseService.getPhotoImportJob(
            job.userId,
            job.jobId,
          );
          if (currentJob?.status == PhotoImportJobStatus.cancelled) {
            return;
          }
          await _databaseService.savePhotoImportJob(
            job.userId,
            job.copyWith(
              status: PhotoImportJobStatus.processing,
              processedImages: processedCount,
              createdDrafts: createdDrafts,
              updatedAt: DateTime.now(),
            ),
          );
        },
      );

      final currentJob = await _databaseService.getPhotoImportJob(
        job.userId,
        job.jobId,
      );
      if (currentJob?.status == PhotoImportJobStatus.cancelled) {
        return;
      }

      await _databaseService.savePhotoImportJob(
        job.userId,
        job.copyWith(
          status: PhotoImportJobStatus.completed,
          processedImages: result.processedImages,
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
