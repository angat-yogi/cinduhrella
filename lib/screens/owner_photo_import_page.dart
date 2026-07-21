import 'dart:io';

import 'package:cinduhrella/models/photo_import_job.dart';
import 'package:cinduhrella/models/user_profile.dart';
import 'package:cinduhrella/screens/review_detected_items_page.dart';
import 'package:cinduhrella/services/alert_service.dart';
import 'package:cinduhrella/services/auth_service.dart';
import 'package:cinduhrella/services/database_service.dart';
import 'package:cinduhrella/services/media_service.dart';
import 'package:cinduhrella/services/owner_photo_import_service.dart';
import 'package:cinduhrella/services/storage_service.dart';
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
  late final StorageService _storageService;
  final TextEditingController _ownerHintController = TextEditingController();

  List<PhotoLibraryCollection> _collections = const [];
  List<File> _selectedImages = const [];
  File? _ownerReferenceFile;
  PhotoLibraryCollection? _selectedCollection;
  bool _loadingCollections = false;
  bool _processing = false;
  bool _consentGranted = false;
  bool _ownerOnlyMode = true;
  PhotoImportJob? _lastQueuedJob;
  UserProfile? _profile;

  static const List<String> _guidedSteps = [
    'Open Apple Photos.',
    'Create or choose one personal album just for your own outfits.',
    'Add your photos to that album.',
    'Come back here and select that album in Cinduhrella.',
  ];

  @override
  void initState() {
    super.initState();
    _mediaService = _getIt.get<MediaService>();
    _importService = _getIt.get<OwnerPhotoImportService>();
    _authService = _getIt.get<AuthService>();
    _databaseService = _getIt.get<DatabaseService>();
    _alertService = _getIt.get<AlertService>();
    _storageService = _getIt.get<StorageService>();
    _loadProfile();
    _loadCollections();
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
      _ownerHintController.text = preferences.ownerIdentityHint.isNotEmpty
          ? preferences.ownerIdentityHint
          : (profile.fullName?.trim().isNotEmpty == true
              ? profile.fullName!.trim()
              : (profile.userName ?? '').trim());
    });
    _syncSelectedCollectionFromPreferences();
  }

  Future<void> _loadCollections() async {
    setState(() {
      _loadingCollections = true;
    });
    final collections = await _mediaService.getImageCollections();
    if (!mounted) {
      return;
    }
    setState(() {
      _collections = collections;
      _loadingCollections = false;
    });
    _syncSelectedCollectionFromPreferences();
  }

  void _syncSelectedCollectionFromPreferences() {
    final profile = _profile;
    if (profile == null || _collections.isEmpty) {
      return;
    }

    final targetId = profile.photoImportPreferences.sourceCollectionId.trim();
    if (targetId.isEmpty) {
      return;
    }

    for (final collection in _collections) {
      if (collection.id == targetId) {
        if (_selectedCollection?.id != collection.id) {
          setState(() {
            _selectedCollection = collection;
          });
        }
        return;
      }
    }
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

  Future<void> _pickOwnerReferencePhoto() async {
    final image = await _mediaService.getImageFromGallery();
    if (!mounted || image == null) {
      return;
    }
    setState(() {
      _ownerReferenceFile = image;
    });
  }

  Future<void> _pickCollection() async {
    if (_loadingCollections) {
      return;
    }
    if (_collections.isEmpty) {
      await _loadCollections();
    }
    if (!mounted || _collections.isEmpty) {
      _alertService.showToast(
        text: 'No personal albums found yet. Create one in Photos first.',
        icon: Icons.photo_library_outlined,
      );
      return;
    }

    final selected = await showModalBottomSheet<PhotoLibraryCollection>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: _collections.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final collection = _collections[index];
              final isActive = collection.id == _selectedCollection?.id;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: isActive
                      ? const Color(0xFF6D56A8)
                      : const Color(0xFFECE7FA),
                  foregroundColor:
                      isActive ? Colors.white : const Color(0xFF6D56A8),
                  child: Icon(
                    isActive
                        ? Icons.check_rounded
                        : Icons.collections_bookmark_outlined,
                  ),
                ),
                title: Text(collection.name),
                subtitle: Text('${collection.assetCount} photo(s)'),
                onTap: () => Navigator.of(context).pop(collection),
              );
            },
          ),
        );
      },
    );

    if (!mounted || selected == null) {
      return;
    }
    setState(() {
      _selectedCollection = selected;
    });
  }

  Future<UserProfile?> _prepareProfileForImport(UserProfile profile) async {
    final ownerReferences = <String>[
      ...profile.photoImportPreferences.ownerReferenceImageUrls,
      if ((profile.profilePictureUrl ?? '').trim().isNotEmpty)
        profile.profilePictureUrl!.trim(),
    ];

    if (_ownerReferenceFile != null) {
      final uploadedUrl = await _storageService.uploadOwnerReferenceImage(
        file: _ownerReferenceFile!,
        uid: profile.uid!,
      );
      if (uploadedUrl != null && !ownerReferences.contains(uploadedUrl)) {
        ownerReferences.insert(0, uploadedUrl);
      }
    }

    if (ownerReferences.isEmpty) {
      _alertService.showToast(
        text:
            'Add one face reference first so we can validate which person is you.',
        icon: Icons.face_retouching_natural_outlined,
      );
      return null;
    }

    final preferences = profile.photoImportPreferences.copyWith(
      consentGranted: true,
      consentedAt: DateTime.now(),
      ownerOnlyImportEnabled: _ownerOnlyMode,
      ownerReferenceImageUrls: ownerReferences.take(3).toList(),
      ownerIdentityHint: _ownerHintController.text.trim(),
    );
    await _importService.updatePreferences(
      profile: profile,
      preferences: preferences,
    );

    return UserProfile(
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
  }

  Future<void> _startImport() async {
    final profile = _profile;
    if (profile == null || !_consentGranted || _selectedImages.isEmpty) {
      return;
    }

    setState(() {
      _processing = true;
    });

    final refreshedProfile = await _prepareProfileForImport(profile);
    if (refreshedProfile == null) {
      if (mounted) {
        setState(() {
          _processing = false;
        });
      }
      return;
    }

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

  Future<void> _startCollectionSync() async {
    final profile = _profile;
    final collection = _selectedCollection;
    if (profile == null || !_consentGranted || collection == null) {
      return;
    }

    setState(() {
      _processing = true;
    });

    final refreshedProfile = await _prepareProfileForImport(profile);
    if (refreshedProfile == null) {
      if (mounted) {
        setState(() {
          _processing = false;
        });
      }
      return;
    }

    final preferences = refreshedProfile.photoImportPreferences.copyWith(
      sourceCollectionId: collection.id,
      sourceCollectionName: collection.name,
      collectionAutoSyncEnabled: true,
    );

    await _importService.updatePreferences(
      profile: refreshedProfile,
      preferences: preferences,
    );

    final savedProfile = UserProfile(
      uid: refreshedProfile.uid,
      fullName: refreshedProfile.fullName,
      profilePictureUrl: refreshedProfile.profilePictureUrl,
      userName: refreshedProfile.userName,
      followingCount: refreshedProfile.followingCount,
      followersCount: refreshedProfile.followersCount,
      postCount: refreshedProfile.postCount,
      following: refreshedProfile.following,
      followers: refreshedProfile.followers,
      posts: refreshedProfile.posts,
      bodyMeasurements: refreshedProfile.bodyMeasurements,
      stylePreferences: refreshedProfile.stylePreferences,
      photoImportPreferences: preferences,
    );

    try {
      final queuedJob = await _importService.syncSelectedCollectionIfNeeded(
        profile: savedProfile,
        force: true,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _processing = false;
        _profile = savedProfile;
        _lastQueuedJob = queuedJob;
      });

      _alertService.showToast(
        text: queuedJob == null
            ? 'No new photos found in ${collection.name}.'
            : 'Collection sync started from ${collection.name}.',
        icon: Icons.sync,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _processing = false;
        _profile = savedProfile;
      });
      _alertService.showToast(
        text:
            'Album sync failed. Refresh the album and try again, or use manual photo selection below.',
        icon: Icons.error_outline,
      );
    }
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
                    'Set up one personal album first, then Cinduhrella will sync only that album while you use the app. You can still manually pick photos whenever you want.',
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
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F6FC),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Guided setup',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ...List.generate(_guidedSteps.length, (index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  alignment: Alignment.center,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFE6DFF8),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF6D56A8),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _guidedSteps[index],
                                    style: const TextStyle(
                                      color: Color(0xFF4E475B),
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 6),
                        const Text(
                          'iPhone does not expose named People & Pets identities directly to third-party apps. A personal album is the reliable source we can keep in sync.',
                          style: TextStyle(
                            color: Color(0xFF6C647A),
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed:
                                    _processing ? null : _loadCollections,
                                icon: _loadingCollections
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.refresh_rounded),
                                label: const Text('Refresh Albums'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: _processing ? null : _pickCollection,
                                icon: const Icon(
                                  Icons.collections_bookmark_outlined,
                                ),
                                label: Text(
                                  _selectedCollection == null
                                      ? 'Choose Album'
                                      : 'Change Album',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 22,
                      backgroundColor: const Color(0xFFECE7FA),
                      foregroundColor: const Color(0xFF6D56A8),
                      child: const Icon(Icons.photo_album_outlined),
                    ),
                    title: const Text('Selected personal album'),
                    subtitle: Text(
                      _selectedCollection != null
                          ? '${_selectedCollection!.name} • ${_selectedCollection!.assetCount} photo(s)'
                          : ((_profile?.photoImportPreferences
                                          .sourceCollectionName ??
                                      '')
                                  .trim()
                                  .isNotEmpty
                              ? _profile!.photoImportPreferences
                                  .sourceCollectionName
                              : 'No personal album selected yet.'),
                    ),
                  ),
                  if (_collections.isEmpty && !_loadingCollections)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: Text(
                        'No user-created albums are visible yet. Create one in Photos, add your images there, then tap Refresh Albums.',
                        style: TextStyle(
                          color: Color(0xFF6C647A),
                          height: 1.4,
                        ),
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
                        'I allow Cinduhrella to analyze personal photos for clothing import'),
                    subtitle: const Text(
                      'Imported clothes always stay pending until I confirm them.',
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
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      radius: 22,
                      backgroundColor: const Color(0xFFECE7FA),
                      backgroundImage: _ownerReferenceFile != null
                          ? FileImage(_ownerReferenceFile!)
                          : null,
                      child: _ownerReferenceFile == null
                          ? const Icon(
                              Icons.face_retouching_natural_outlined,
                              color: Color(0xFF6D56A8),
                            )
                          : null,
                    ),
                    title: const Text('Owner validation photo'),
                    subtitle: Text(
                      (_profile?.photoImportPreferences.ownerReferenceImageUrls
                                      .isNotEmpty ??
                                  false) ||
                              (_profile?.profilePictureUrl?.trim().isNotEmpty ??
                                  false) ||
                              _ownerReferenceFile != null
                          ? 'Ready. We will use your profile face or the photo you picked.'
                          : 'Pick one clear face photo the first time so we can validate which person is you.',
                    ),
                    trailing: TextButton(
                      onPressed: _processing ? null : _pickOwnerReferencePhoto,
                      child: Text(
                        _ownerReferenceFile == null ? 'Pick' : 'Change',
                      ),
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 8, bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F6FC),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Text(
                      'Manual fallback: if you do not want album sync, choose only the exact photos you want below.',
                      style: TextStyle(
                        color: Color(0xFF6C647A),
                        height: 1.4,
                      ),
                    ),
                  ),
                  TextField(
                    controller: _ownerHintController,
                    decoration: const InputDecoration(
                      labelText: 'Owner hint',
                      hintText:
                          'Example: Angat | use my face reference | prioritize the person centered in selfies',
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _processing ||
                            !_consentGranted ||
                            _selectedCollection == null
                        ? null
                        : _startCollectionSync,
                    icon: const Icon(Icons.sync),
                    label: Text(
                      _selectedCollection == null
                          ? 'Choose An Album First'
                          : 'Save Album & Start Sync',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    (_profile?.photoImportPreferences.collectionAutoSyncEnabled ??
                            false)
                        ? 'Foreground sync is enabled for ${_profile?.photoImportPreferences.sourceCollectionName.isNotEmpty == true ? _profile!.photoImportPreferences.sourceCollectionName : "your selected album"}.'
                        : 'You can still manually choose photos below if you prefer.',
                    style: const TextStyle(color: Color(0xFF6C647A)),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _processing ? null : _pickImages,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: Text(
                      _selectedImages.isEmpty
                          ? 'Choose My Photos'
                          : 'Selected ${_selectedImages.length} photo(s)',
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Only the photos you select here will be processed.',
                    style: TextStyle(color: Color(0xFF6C647A)),
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
        child: FilledButton.icon(
          onPressed: _processing || !_consentGranted || _selectedImages.isEmpty
              ? null
              : _startImport,
          icon: const Icon(Icons.upload_file_outlined),
          label: Text(
            _processing ? 'Processing...' : 'Send Clothes To Pending Review',
          ),
        ),
      ),
    );
  }
}
