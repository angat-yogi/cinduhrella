import 'dart:io';

import 'package:cinduhrella/models/body_profile.dart';
import 'package:cinduhrella/models/body_measurements.dart';
import 'package:cinduhrella/models/cloth.dart';
import 'package:cinduhrella/models/garment_asset.dart';
import 'package:cinduhrella/models/outfit_recommendation.dart';
import 'package:cinduhrella/models/style_brief.dart';
import 'package:cinduhrella/models/try_on.dart';
import 'package:cinduhrella/models/try_on_job.dart';
import 'package:cinduhrella/models/user_profile.dart';
import 'package:cinduhrella/services/chat_service.dart';
import 'package:cinduhrella/services/database_service.dart';
import 'package:cinduhrella/services/storage_service.dart';
import 'package:cinduhrella/services/try_on_renderer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';

class TryOnService {
  TryOnService() {
    final getIt = GetIt.instance;
    _renderer = getIt.get<TryOnRenderer>();
    _databaseService = getIt.get<DatabaseService>();
    _storageService = getIt.get<StorageService>();
    _chatService = getIt.get<ChatService>();
  }

  late final TryOnRenderer _renderer;
  late final DatabaseService _databaseService;
  late final StorageService _storageService;
  late final ChatService _chatService;

  Future<TryOnPreview> generatePreview({
    required String userId,
    required UserProfile profile,
    required OutfitRecommendation recommendation,
    required StyleBrief brief,
  }) async {
    return _renderer.render(
      TryOnRequest(
        userId: userId,
        baseImageUrl: profile.profilePictureUrl,
        bodyMeasurements: profile.bodyMeasurements,
        silhouette: brief.silhouette,
        clothes: recommendation.clothes,
        occasionTags: recommendation.matchedOccasions.isEmpty
            ? brief.occasionTags
            : recommendation.matchedOccasions,
      ),
    );
  }

  Future<BodyProfile> createBodyProfile({
    required String userId,
    required File frontImage,
    required BodyMeasurements measurements,
    bool isPrimary = true,
  }) async {
    final bodyProfileId =
        FirebaseFirestore.instance.collection('tmpBodyProfiles').doc().id;
    final imageUrl = await _storageService.uploadBodyProfileImage(
      file: frontImage,
      uid: userId,
      bodyProfileId: bodyProfileId,
    );
    final bodyProfile = BodyProfile(
      bodyProfileId: bodyProfileId,
      uid: userId,
      frontImageUrl: imageUrl ?? '',
      measurements: measurements,
      isPrimary: isPrimary,
      createdAt: DateTime.now(),
    );
    await _databaseService.saveBodyProfile(userId, bodyProfile);
    return bodyProfile;
  }

  Future<GarmentAsset> createGarmentAssetFromUpload({
    required String userId,
    required File image,
    required String category,
  }) async {
    final garmentAssetId =
        FirebaseFirestore.instance.collection('tmpGarmentAssets').doc().id;
    final imageUrl = await _storageService.uploadGarmentAssetImage(
      file: image,
      uid: userId,
      garmentAssetId: garmentAssetId,
    );
    final details = imageUrl == null
        ? <String, String>{}
        : await _chatService.getClothingDetailsFromChatGPT(imageUrl);
    final garmentAsset = GarmentAsset(
      garmentAssetId: garmentAssetId,
      uid: userId,
      imageUrl: imageUrl ?? '',
      category: category,
      brand: details['brand'],
      color: details['color'],
      size: details['size'],
      description: details['description'],
      createdAt: DateTime.now(),
    );
    await _databaseService.saveGarmentAsset(userId, garmentAsset);
    return garmentAsset;
  }

  Future<GarmentAsset> createGarmentAssetFromCloth({
    required String userId,
    required Cloth cloth,
    required String category,
  }) async {
    final garmentAssetId =
        FirebaseFirestore.instance.collection('tmpGarmentAssets').doc().id;
    final garmentAsset = GarmentAsset(
      garmentAssetId: garmentAssetId,
      uid: userId,
      imageUrl: cloth.imageUrl ?? '',
      category: category,
      brand: cloth.brand,
      color: cloth.color,
      size: cloth.size,
      description: cloth.description,
      sourceClothId: cloth.clothId,
      createdAt: DateTime.now(),
    );
    await _databaseService.saveGarmentAsset(userId, garmentAsset);
    return garmentAsset;
  }

  Future<TryOnJob> submitTryOnJob({
    required String userId,
    required BodyProfile bodyProfile,
    required GarmentAsset topGarment,
    required GarmentAsset bottomGarment,
    required StyleBrief brief,
  }) async {
    final preview = await _renderer.render(
      TryOnRequest(
        userId: userId,
        baseImageUrl: bodyProfile.frontImageUrl,
        bodyMeasurements: bodyProfile.measurements,
        silhouette: brief.silhouette,
        clothes: [
          _toCloth(userId, topGarment),
          _toCloth(userId, bottomGarment),
        ],
        occasionTags: brief.occasionTags,
      ),
    );

    final job = TryOnJob(
      tryOnJobId:
          FirebaseFirestore.instance.collection('tmpTryOnJobs').doc().id,
      uid: userId,
      bodyProfileId: bodyProfile.bodyProfileId,
      topGarmentId: topGarment.garmentAssetId,
      bottomGarmentId: bottomGarment.garmentAssetId,
      outputView: 'front',
      status: preview.readyForRemoteRenderer
          ? TryOnJobStatus.completed
          : TryOnJobStatus.queued,
      resultImageUrl: preview.assetUrl,
      summary: preview.summary,
      renderPrompt: preview.renderPrompt,
      createdAt: DateTime.now(),
    );

    await _databaseService.saveTryOnJob(userId, job);
    return job;
  }

  Future<List<BodyProfile>> getBodyProfiles(String userId) {
    return _databaseService.getBodyProfiles(userId);
  }

  Future<List<GarmentAsset>> getGarmentAssets(
    String userId, {
    String? category,
  }) {
    return _databaseService.getGarmentAssets(userId, category: category);
  }

  Stream<List<TryOnJob>> getTryOnJobsStream(String userId) {
    return _databaseService.getTryOnJobsStream(userId);
  }

  Future<BodyProfile?> getOrCreateDefaultBodyProfile(
      UserProfile profile) async {
    final userId = profile.uid;
    if (userId == null) {
      return null;
    }
    final existing = await _databaseService.getPrimaryBodyProfile(userId);
    if (existing != null) {
      return existing;
    }
    if ((profile.profilePictureUrl ?? '').isEmpty) {
      return null;
    }
    final bodyProfile = BodyProfile(
      bodyProfileId:
          FirebaseFirestore.instance.collection('tmpBodyProfiles').doc().id,
      uid: userId,
      frontImageUrl: profile.profilePictureUrl ?? '',
      measurements: profile.bodyMeasurements,
      isPrimary: true,
      createdAt: DateTime.now(),
    );
    await _databaseService.saveBodyProfile(userId, bodyProfile);
    return bodyProfile;
  }

  Cloth _toCloth(String userId, GarmentAsset garmentAsset) {
    return Cloth(
      clothId: garmentAsset.garmentAssetId,
      storageId: null,
      uid: userId,
      imageUrl: garmentAsset.imageUrl,
      brand: garmentAsset.brand,
      size: garmentAsset.size,
      description: garmentAsset.description,
      type: garmentAsset.category == 'top' ? 'Top Wear' : 'Bottom Wear',
      color: garmentAsset.color,
    );
  }
}
