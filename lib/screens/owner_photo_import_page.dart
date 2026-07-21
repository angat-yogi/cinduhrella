import 'dart:io';

import 'package:cinduhrella/models/photo_import_job.dart';
import 'package:cinduhrella/models/user_profile.dart';
import 'package:cinduhrella/screens/review_detected_items_page.dart';
import 'package:cinduhrella/services/alert_service.dart';
import 'package:cinduhrella/services/auth_service.dart';
import 'package:cinduhrella/services/database_service.dart';
import 'package:cinduhrella/services/media_service.dart';
import 'package:cinduhrella/services/owner_photo_import_service.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

class OwnerPhotoImportPage extends StatefulWidget {
  const OwnerPhotoImportPage({super.key});

  @override
  State<OwnerPhotoImportPage> createState() => _OwnerPhotoImportPageState();
}

class _OwnerPhotoImportPageState extends State<OwnerPhotoImportPage> {
  final GetIt _getIt = GetIt.instance;
  late final MediaService _mediaService;
  late final OwnerPhotoImportService _importService;
  late final AuthService _authService;
  late final DatabaseService _databaseService;
  late final AlertService _alertService;
  final TextEditingController _ownerHintController = TextEditingController();

  List<File> _selectedImages = const [];
  bool _processing = false;
  bool _consentGranted = false;
  bool _ownerOnlyMode = true;
  PhotoImportJob? _lastQueuedJob;
  UserProfile? _profile;

  @override
  void initState() {
    super.initState();
    _mediaService = _getIt.get<MediaService>();
    _importService = _getIt.get<OwnerPhotoImportService>();
    _authService = _getIt.get<AuthService>();
    _databaseService = _getIt.get<DatabaseService>();
    _alertService = _getIt.get<AlertService>();
    _loadProfile();
  }

  @override
  void dispose() {
    _ownerHintController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final userId = _authService.user?.uid;
    if (userId == null) {
      return;
    }
    final profile = await _databaseService.getUserProfile(uid: userId);
    if (!mounted || profile == null) {
      return;
    }
    final preferences = profile.photoImportPreferences;
    setState(() {
      _profile = profile;
      _consentGranted = preferences.consentGranted;
      _ownerOnlyMode = preferences.ownerOnlyImportEnabled;
      _ownerHintController.text = preferences.ownerIdentityHint;
    });
  }

  Future<void> _pickImages() async {
    final images = await _mediaService.getImagesFromGallery();
    if (!mounted) {
      return;
    }
    setState(() {
      _selectedImages = images;
    });
  }

  Future<void> _startImport() async {
    final profile = _profile;
    if (profile == null || !_consentGranted || _selectedImages.isEmpty) {
      return;
    }

    setState(() {
      _processing = true;
    });

    final ownerReferences = <String>[
      if ((profile.profilePictureUrl ?? '').trim().isNotEmpty)
        profile.profilePictureUrl!.trim(),
    ];
    final preferences = profile.photoImportPreferences.copyWith(
      consentGranted: true,
      consentedAt: DateTime.now(),
      ownerOnlyImportEnabled: _ownerOnlyMode,
      ownerReferenceImageUrls: ownerReferences,
      ownerIdentityHint: _ownerHintController.text.trim(),
    );
    await _importService.updatePreferences(
      profile: profile,
      preferences: preferences,
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
      photoImportPreferences: preferences,
    );

    final queuedJob = await _importService.queueOwnerPhotoImport(
      profile: refreshedProfile,
      images: _selectedImages,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _processing = false;
      _profile = refreshedProfile;
      _lastQueuedJob = queuedJob;
    });

    _alertService.showToast(
      text:
          'Import started. You can browse the rest of the app while photos are processed into pending review.',
      icon: Icons.check_circle,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Import From My Photos'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Owner-photo import',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Select photos from your iPhone library. The app will try to pull only clothes worn by the likely phone owner, then place them into pending review instead of adding them directly to the closet.',
                  ),
                  const SizedBox(height: 16),
                  if (_lastQueuedJob != null)
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Latest import queued. You can leave this screen and come back later to review pending items from Home.',
                      ),
                    ),
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _consentGranted,
                    onChanged: _processing
                        ? null
                        : (value) {
                            setState(() {
                              _consentGranted = value ?? false;
                            });
                          },
                    title: const Text(
                        'I allow Cinduhrella to analyze selected personal photos'),
                    subtitle: const Text(
                      'Only selected photos are processed. Imported clothes always stay pending until I confirm them.',
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: _ownerOnlyMode,
                    onChanged: _processing
                        ? null
                        : (value) {
                            setState(() {
                              _ownerOnlyMode = value;
                            });
                          },
                    title: const Text('Owner-only extraction'),
                    subtitle: const Text(
                      'Prefer clothing worn by the likely phone owner and ignore other people when possible.',
                    ),
                  ),
                  TextField(
                    controller: _ownerHintController,
                    decoration: const InputDecoration(
                      labelText: 'Owner hint',
                      hintText:
                          'Example: Use my profile photo and focus on the person I usually photograph',
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _processing ? null : _pickImages,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: Text(
                      _selectedImages.isEmpty
                          ? 'Choose Personal Photos'
                          : 'Selected ${_selectedImages.length} photo(s)',
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: _processing || _lastQueuedJob?.sessionId == null
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ReviewDetectedItemsPage(
                                  sessionId: _lastQueuedJob!.sessionId!,
                                ),
                              ),
                            );
                          },
                    icon: const Icon(Icons.fact_check_outlined),
                    label: const Text('Open Latest Pending Review'),
                  ),
                ],
              ),
            ),
          ),
          if (_selectedImages.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Selected photos',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 110,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedImages.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _selectedImages[index],
                      width: 110,
                      height: 110,
                      fit: BoxFit.cover,
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: FilledButton(
          onPressed: _processing || !_consentGranted || _selectedImages.isEmpty
              ? null
              : _startImport,
          child: Text(
            _processing ? 'Importing...' : 'Send Clothes To Pending Review',
          ),
        ),
      ),
    );
  }
}
