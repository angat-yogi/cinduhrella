import 'dart:io';

import 'package:cinduhrella/models/body_measurements.dart';
import 'package:cinduhrella/models/body_profile.dart';
import 'package:cinduhrella/models/garment_asset.dart';
import 'package:cinduhrella/models/style_brief.dart';
import 'package:cinduhrella/models/try_on_job.dart';
import 'package:cinduhrella/models/user_profile.dart';
import 'package:cinduhrella/services/alert_service.dart';
import 'package:cinduhrella/services/auth_service.dart';
import 'package:cinduhrella/services/database_service.dart';
import 'package:cinduhrella/services/media_service.dart';
import 'package:cinduhrella/services/try_on_service.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

class TryOnStudioPage extends StatefulWidget {
  const TryOnStudioPage({super.key});

  @override
  State<TryOnStudioPage> createState() => _TryOnStudioPageState();
}

class _TryOnStudioPageState extends State<TryOnStudioPage> {
  final GetIt _getIt = GetIt.instance;
  late final TryOnService _tryOnService;
  late final MediaService _mediaService;
  late final AuthService _authService;
  late final DatabaseService _databaseService;
  late final AlertService _alertService;

  File? _bodyPhoto;
  File? _topPhoto;
  File? _bottomPhoto;
  bool _submitting = false;
  UserProfile? _profile;
  List<BodyProfile> _bodyProfiles = const [];
  List<GarmentAsset> _topAssets = const [];
  List<GarmentAsset> _bottomAssets = const [];
  BodyProfile? _selectedBodyProfile;
  GarmentAsset? _selectedTopAsset;
  GarmentAsset? _selectedBottomAsset;

  @override
  void initState() {
    super.initState();
    _tryOnService = _getIt.get<TryOnService>();
    _mediaService = _getIt.get<MediaService>();
    _authService = _getIt.get<AuthService>();
    _databaseService = _getIt.get<DatabaseService>();
    _alertService = _getIt.get<AlertService>();
    _loadData();
  }

  Future<void> _loadData() async {
    final userId = _authService.user?.uid;
    if (userId == null) {
      return;
    }

    final profile = await _databaseService.getUserProfile(uid: userId);
    final bodyProfiles = await _tryOnService.getBodyProfiles(userId);
    final topAssets =
        await _tryOnService.getGarmentAssets(userId, category: 'top');
    final bottomAssets =
        await _tryOnService.getGarmentAssets(userId, category: 'bottom');

    if (!mounted) {
      return;
    }

    setState(() {
      _profile = profile;
      _bodyProfiles = bodyProfiles;
      _topAssets = topAssets;
      _bottomAssets = bottomAssets;
      _selectedBodyProfile =
          bodyProfiles.isNotEmpty ? bodyProfiles.first : _selectedBodyProfile;
      _selectedTopAsset =
          topAssets.isNotEmpty ? topAssets.first : _selectedTopAsset;
      _selectedBottomAsset =
          bottomAssets.isNotEmpty ? bottomAssets.first : _selectedBottomAsset;
    });
  }

  Future<void> _pickBodyPhoto() async {
    final file = await _mediaService.getImageFromGallery();
    if (file == null || !mounted) {
      return;
    }
    setState(() {
      _bodyPhoto = file;
    });
  }

  Future<void> _pickGarmentPhoto(String category) async {
    final file = await _mediaService.getImageFromGallery();
    if (file == null || !mounted) {
      return;
    }
    setState(() {
      if (category == 'top') {
        _topPhoto = file;
      } else {
        _bottomPhoto = file;
      }
    });
  }

  Future<void> _submitJob() async {
    final userId = _authService.user?.uid;
    final profile = _profile;
    if (userId == null || profile == null) {
      return;
    }

    setState(() {
      _submitting = true;
    });

    BodyProfile? bodyProfile = _selectedBodyProfile;
    if (bodyProfile == null && _bodyPhoto != null) {
      bodyProfile = await _tryOnService.createBodyProfile(
        userId: userId,
        frontImage: _bodyPhoto!,
        measurements: profile.bodyMeasurements,
      );
    }
    bodyProfile ??= await _tryOnService.getOrCreateDefaultBodyProfile(profile);

    GarmentAsset? topAsset = _selectedTopAsset;
    if (topAsset == null && _topPhoto != null) {
      topAsset = await _tryOnService.createGarmentAssetFromUpload(
        userId: userId,
        image: _topPhoto!,
        category: 'top',
      );
    }

    GarmentAsset? bottomAsset = _selectedBottomAsset;
    if (bottomAsset == null && _bottomPhoto != null) {
      bottomAsset = await _tryOnService.createGarmentAssetFromUpload(
        userId: userId,
        image: _bottomPhoto!,
        category: 'bottom',
      );
    }

    if (bodyProfile == null || topAsset == null || bottomAsset == null) {
      if (mounted) {
        _alertService.showToast(
          text: 'Body photo plus top and bottom garments are required.',
          icon: Icons.error,
        );
      }
      setState(() {
        _submitting = false;
      });
      return;
    }

    await _tryOnService.submitTryOnJob(
      userId: userId,
      bodyProfile: bodyProfile,
      topGarment: topAsset,
      bottomGarment: bottomAsset,
      brief: StyleBrief(
        focus: PlanningFocus.everyday,
        title: 'Studio Preview',
        context: 'Direct upload try-on',
        mood: 'neutral',
        climate: ClimateBand.mild,
        dressCode: DressCode.smartCasual,
        silhouette: SilhouetteProfile.balanced,
        occasionTags: const [OccasionTag.casual],
      ),
    );

    await _loadData();
    if (!mounted) {
      return;
    }
    _alertService.showToast(
      text: 'Try-on job created.',
      icon: Icons.check_circle,
    );
    setState(() {
      _submitting = false;
      _bodyPhoto = null;
      _topPhoto = null;
      _bottomPhoto = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userId = _authService.user?.uid;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Try-On Studio'),
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: userId == null
          ? const Center(child: Text('Sign in to use Try-On Studio.'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _introCard(),
                const SizedBox(height: 16),
                _uploadCard(),
                const SizedBox(height: 16),
                _savedAssetsCard(),
                const SizedBox(height: 16),
                _jobsCard(userId),
              ],
            ),
      bottomNavigationBar: userId == null
          ? null
          : Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton(
                onPressed: _submitting ? null : _submitJob,
                child:
                    Text(_submitting ? 'Creating Job...' : 'Create Try-On Job'),
              ),
            ),
    );
  }

  Widget _introCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Static Try-On Studio',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Upload one front-facing body photo, one shirt photo, and one pant photo. The app stores them as reusable assets and creates a static try-on job.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _uploadCard() {
    final measurements = _profile?.bodyMeasurements ?? const BodyMeasurements();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'New Inputs',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _pickRow(
              label: 'Body Photo',
              file: _bodyPhoto,
              onTap: _pickBodyPhoto,
            ),
            const SizedBox(height: 12),
            _pickRow(
              label: 'Top Garment',
              file: _topPhoto,
              onTap: () => _pickGarmentPhoto('top'),
            ),
            const SizedBox(height: 12),
            _pickRow(
              label: 'Bottom Garment',
              file: _bottomPhoto,
              onTap: () => _pickGarmentPhoto('bottom'),
            ),
            const SizedBox(height: 12),
            Text(
              measurements.hasEnoughDataForPreview
                  ? 'Measurements are available for fitting and scaling.'
                  : 'Measurements are still incomplete. Preview quality will be limited.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _savedAssetsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Saved Assets',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<BodyProfile>(
              value: _selectedBodyProfile,
              decoration: const InputDecoration(
                labelText: 'Body Profile',
                border: OutlineInputBorder(),
              ),
              items: _bodyProfiles
                  .map(
                    (profile) => DropdownMenuItem(
                      value: profile,
                      child: Text(
                        profile.isPrimary
                            ? 'Primary body profile'
                            : 'Body profile ${profile.createdAt.month}/${profile.createdAt.day}',
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedBodyProfile = value;
                });
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<GarmentAsset>(
              value: _selectedTopAsset,
              decoration: const InputDecoration(
                labelText: 'Top Asset',
                border: OutlineInputBorder(),
              ),
              items: _topAssets
                  .map(
                    (asset) => DropdownMenuItem(
                      value: asset,
                      child: Text(_assetLabel(asset)),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedTopAsset = value;
                });
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<GarmentAsset>(
              value: _selectedBottomAsset,
              decoration: const InputDecoration(
                labelText: 'Bottom Asset',
                border: OutlineInputBorder(),
              ),
              items: _bottomAssets
                  .map(
                    (asset) => DropdownMenuItem(
                      value: asset,
                      child: Text(_assetLabel(asset)),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedBottomAsset = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _jobsCard(String userId) {
    return StreamBuilder<List<TryOnJob>>(
      stream: _tryOnService.getTryOnJobsStream(userId),
      builder: (context, snapshot) {
        final jobs = snapshot.data ?? const <TryOnJob>[];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Recent Jobs',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                if (jobs.isEmpty)
                  const Text('No try-on jobs yet.')
                else
                  ...jobs.map(
                    (job) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blueGrey.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              job.status.name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(job.summary),
                            const SizedBox(height: 4),
                            Text(
                              'View: ${job.outputView} • ${job.createdAt.month}/${job.createdAt.day}',
                            ),
                            if ((job.resultImageUrl ?? '').isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Image.network(
                                job.resultImageUrl!,
                                height: 160,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const SizedBox(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _pickRow({
    required String label,
    required File? file,
    required VoidCallback onTap,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(label),
        ),
        if (file != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              file,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
            ),
          ),
        const SizedBox(width: 12),
        OutlinedButton(
          onPressed: onTap,
          child: Text(file == null ? 'Choose' : 'Replace'),
        ),
      ],
    );
  }

  String _assetLabel(GarmentAsset asset) {
    final pieces = [
      asset.brand,
      asset.color,
      asset.description,
    ].whereType<String>().where((value) => value.isNotEmpty).join(' • ');
    return pieces.isEmpty ? asset.category : pieces;
  }
}
