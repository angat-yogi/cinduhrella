import 'dart:async';
import 'package:cinduhrella/models/draft_cloth.dart';
import 'package:cinduhrella/models/photo_import_job.dart';
import 'package:cinduhrella/models/styled_outfit.dart';
import 'package:cinduhrella/models/user_profile.dart';
import 'package:cinduhrella/screens/outfit_feed.dart';
import 'package:cinduhrella/screens/bulk_capture_page.dart';
import 'package:cinduhrella/screens/mix_match_studio_page.dart';
import 'package:cinduhrella/screens/outfit_details_page.dart';
import 'package:cinduhrella/screens/owner_photo_import_page.dart';
import 'package:cinduhrella/screens/planner_page.dart';
import 'package:cinduhrella/screens/review_detected_items_page.dart';
import 'package:cinduhrella/screens/saved_outfit.dart';
import 'package:cinduhrella/screens/trip_page.dart';
import 'package:cinduhrella/services/auth_service.dart';
import 'package:cinduhrella/services/database_service.dart';
import 'package:cinduhrella/services/owner_photo_import_service.dart';
import 'package:cinduhrella/shared/add_item.dart';
import 'package:cinduhrella/shared/app_drawer.dart';
import 'package:cinduhrella/shared/custom_bar.dart';
import 'package:cinduhrella/shared/styled_outfit_preview.dart';
import 'package:cinduhrella/shared/unassigned_item.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  String userName = 'Loading...';
  String profileImageUrl = '';
  final GetIt _getIt = GetIt.instance;
  late AuthService _authService;
  late DatabaseService _databaseService;
  late OwnerPhotoImportService _ownerPhotoImportService;
  int _selectedIndex = 0;
  final List<String> _commonSearches = [
    "Black T-shirt",
    "Nike Shoes",
    "Formal Suit",
    "Leather Jacket",
    "Casual Jeans",
    "Adidas Sneakers",
    "Zara Dress",
    "Gucci Handbag"
  ];

  // ✅ Variables to manage dynamic hint text
  int currentHintIndex = 0;
  Timer? hintTimer;
  int _studioRefreshToken = 0;
  late final ValueNotifier<String> _searchHintNotifier;
  late final Future<UserProfile> _outfitFeedUserFuture;
  bool _collectionSyncInFlight = false;
  bool _photoImportNudgeDismissed = false;
  UserProfile? _homeProfile;
  static const String _photoImportNudgeKey =
      'home_photo_import_nudge_dismissed_v1';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _authService = _getIt.get<AuthService>();
    _databaseService = _getIt.get<DatabaseService>();
    _ownerPhotoImportService = _getIt.get<OwnerPhotoImportService>();
    _searchHintNotifier = ValueNotifier<String>("Search for an item...");
    _outfitFeedUserFuture = _getUserProfileInformation(_authService.user!.uid);
    _loadHomePreferences();
    _fetchProfileDetails();
    _startHintRotation(); // ✅ Start rotating search hints
    unawaited(_maybeStartCollectionSync());
  }

  Future<void> _loadHomePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) {
      return;
    }
    setState(() {
      _photoImportNudgeDismissed = prefs.getBool(_photoImportNudgeKey) ?? false;
    });
  }

  void _startHintRotation() {
    hintTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      currentHintIndex = (currentHintIndex + 1) % _commonSearches.length;
      _searchHintNotifier.value = _commonSearches[currentHintIndex];
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    hintTimer?.cancel(); // ✅ Cancel the hint rotation timer
    _searchHintNotifier.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_maybeStartCollectionSync());
    }
  }

  Future<void> _fetchProfileDetails() async {
    String? uid = _authService.user?.uid;
    if (uid != null) {
      final userProfile = await _databaseService.getUserProfile(uid: uid);
      String? fetchedUserName =
          _authService.user?.displayName ?? userProfile?.userName;
      String? profilePicture =
          _authService.user?.photoURL ?? userProfile?.profilePictureUrl;

      if (mounted) {
        // ✅ Check before calling setState
        setState(() {
          userName = fetchedUserName ?? 'Unknown User';
          profileImageUrl = profilePicture ?? '';
          _homeProfile = userProfile;
        });
      }
    }
  }

  Future<void> _maybeStartCollectionSync() async {
    if (_collectionSyncInFlight) {
      return;
    }

    final uid = _authService.user?.uid;
    if (uid == null) {
      return;
    }

    _collectionSyncInFlight = true;
    try {
      var profile = await _databaseService.getUserProfile(uid: uid);
      if (profile == null) {
        return;
      }
      final curatedProfile =
          await _ownerPhotoImportService.autoCurateOwnerPhotosToAlbumIfNeeded(
        profile: profile,
      );
      profile = curatedProfile ?? profile;
      await _ownerPhotoImportService.syncSelectedCollectionIfNeeded(
        profile: profile,
      );
    } finally {
      _collectionSyncInFlight = false;
    }
  }

  List<Widget> get _widgetOptions => [
        _buildHomePage(),
        PlannerPage(userId: _authService.user!.uid),
        MixMatchStudioPage(
          userId: _authService.user!.uid,
          refreshToken: _studioRefreshToken,
        ),
        TripPage(userId: _authService.user!.uid),
        FutureBuilder<UserProfile>(
          future: _outfitFeedUserFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return const Center(child: Text("Error loading profile"));
            }
            return OutfitFeedPage(currentUser: snapshot.data!);
          },
        ),
      ];
  Future<UserProfile> _getUserProfileInformation(String uid) async {
    return await _databaseService.getUserProfile(uid: uid) ??
        UserProfile(
            uid: uid,
            fullName: "Unknown User",
            profilePictureUrl: "assets/profile_picture.jpg",
            userName: "Unknown");
  }

  void _onItemTapped(int index) {
    setState(() {
      if (index == 2 && _selectedIndex != 2) {
        _studioRefreshToken++;
      }
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _selectedIndex == 2 || _selectedIndex == 4
          ? null
          : CustomAppBar(
              userName: userName,
              profileImageUrl: profileImageUrl,
              searchHintListenable: _searchHintNotifier,
            ),
      drawer: _selectedIndex == 2 || _selectedIndex == 4
          ? null
          : AppDrawer(userName: userName, profileImageUrl: profileImageUrl),
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      floatingActionButton: (_selectedIndex == 0)
          ? FloatingActionButton(
              onPressed: _showHomeAddActions,
              child: const Icon(Icons.add),
            )
          : null,
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.auto_awesome), label: 'Planner'),
          BottomNavigationBarItem(
              icon: Icon(Icons.layers_outlined), label: 'Studio'),
          BottomNavigationBarItem(
              icon: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(Icons.public, size: 24), // Globe icon
                  Positioned(
                    top: 2,
                    right: 2,
                    child: Icon(Icons.flight_takeoff, size: 16), // Small plane
                  ),
                ],
              ),
              label: 'Trips'),
          BottomNavigationBarItem(
              icon: Icon(Icons.explore), label: 'Outfit Feed') // ✅ New
        ],
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor:
            Colors.grey, // ✅ Ensure unselected items are visible
        onTap: _onItemTapped,
      ),
    );
  }

  void _showAddItemDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return const AddItemDialog();
      },
    );
  }

  Future<void> _setPhotoImportNudgeDismissed(bool dismissed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_photoImportNudgeKey, dismissed);
    if (!mounted) {
      return;
    }
    setState(() {
      _photoImportNudgeDismissed = dismissed;
    });
  }

  Future<void> _openPhotoImportManager() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const OwnerPhotoImportPage(),
      ),
    );
    await _fetchProfileDetails();
    unawaited(_maybeStartCollectionSync());
  }

  Future<void> _showStoreImportDialog() async {
    final controller = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Import From Store Link'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Paste an Amazon, Walmart, or product page link. We will use this entry point for online-item import next.',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Store URL',
                  hintText: 'https://...',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(this.context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Store-link import entry added. Product-page parsing is the next step.',
                    ),
                  ),
                );
              },
              child: const Text('Save Link'),
            ),
          ],
        );
      },
    );
    controller.dispose();
  }

  Future<void> _showHomeAddActions() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Add To Closet',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Choose the fastest way to get items into pending review or directly into your closet.',
                  style: TextStyle(color: Color(0xFF6C647A)),
                ),
                const SizedBox(height: 16),
                _homeActionTile(
                  icon: Icons.photo_library_outlined,
                  title: 'My Photos',
                  subtitle:
                      'Manual picks, Cinduhrella album sync, and automation.',
                  onTap: () {
                    Navigator.of(context).pop();
                    _openPhotoImportManager();
                  },
                ),
                _homeActionTile(
                  icon: Icons.camera_outdoor_outlined,
                  title: 'Bulk Capture',
                  subtitle: 'Upload a quick batch of wardrobe photos.',
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.push(
                      this.context,
                      MaterialPageRoute(
                        builder: (context) => const BulkCapturePage(),
                      ),
                    );
                  },
                ),
                _homeActionTile(
                  icon: Icons.add_a_photo_outlined,
                  title: 'Single Item',
                  subtitle: 'Add one image and fill details manually.',
                  onTap: () {
                    Navigator.of(context).pop();
                    _showAddItemDialog(this.context);
                  },
                ),
                _homeActionTile(
                  icon: Icons.shopping_bag_outlined,
                  title: 'Store Link',
                  subtitle:
                      'Amazon, Walmart, or any product page. Entry point ready.',
                  onTap: () {
                    Navigator.of(context).pop();
                    _showStoreImportDialog();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _homeActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: const Color(0xFFECE7FA),
        foregroundColor: const Color(0xFF6D56A8),
        child: Icon(icon),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: onTap,
    );
  }

  Future<void> _cancelPhotoImportJob(String userId, PhotoImportJob job) async {
    await _databaseService.cancelPhotoImportJob(userId, job.jobId);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${job.title} cancelled.')),
    );
  }

  Future<void> _restoreDraftToReview(String userId, DraftCloth draft) async {
    await _databaseService.moveDraftBackToReview(userId, draft.draftId);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Moved back to review.'),
        action: SnackBarAction(
          label: 'Review now',
          onPressed: _openPendingReview,
        ),
      ),
    );
  }

  Future<void> _confirmLaterDraft(String userId, DraftCloth draft) async {
    await _databaseService.confirmDraftItem(userId, draft);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Added to your closet.')),
    );
  }

  Future<void> _dismissLaterDraft(String userId, DraftCloth draft) async {
    await _databaseService.dismissDraftItem(userId, draft.draftId);
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Removed from saved for later.')),
    );
  }

  void _openPendingReview({String? sessionId}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReviewDetectedItemsPage(
          sessionId: sessionId,
        ),
      ),
    );
  }

  Future<void> _showOutfitActions(StyledOutfit outfit) async {
    final userId = _authService.user!.uid;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  outfit.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Choose what you want to edit.',
                  style: TextStyle(color: Color(0xFF6C647A)),
                ),
                const SizedBox(height: 18),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFECE7FA),
                    foregroundColor: Color(0xFF6D56A8),
                    child: Icon(Icons.edit_note_rounded),
                  ),
                  title: const Text('Edit details'),
                  subtitle: const Text('Rename the outfit and add notes.'),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(this.context).push(
                      MaterialPageRoute(
                        builder: (_) => OutfitDetailsPage(
                          userId: userId,
                          outfit: outfit,
                        ),
                      ),
                    );
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE7EEFF),
                    foregroundColor: Color(0xFF4D6CFA),
                    child: Icon(Icons.layers_outlined),
                  ),
                  title: const Text('Edit style'),
                  subtitle:
                      const Text('Open this saved board back inside Studio.'),
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(this.context).push(
                      MaterialPageRoute(
                        builder: (_) => MixMatchStudioPage(
                          userId: userId,
                          initialOutfit: outfit,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSavedOutfitsSection() {
    String userId = _authService.user!.uid;
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Saved Outfits",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        StreamBuilder<QuerySnapshot>(
          stream:
              firestore.collection('users/$userId/styledOutfits').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Text(
                'No saved outfits found!',
                style: TextStyle(fontSize: 16),
              );
            }

            final outfits = snapshot.data!.docs
                .map((doc) => StyledOutfit.fromFirestore(doc))
                .toList();

            return SizedBox(
              height: 308,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: outfits.length,
                itemBuilder: (context, index) {
                  final outfit = outfits[index];

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              SavedOutfitsPage(userId: userId),
                        ),
                      );
                    },
                    onLongPress: () => _showOutfitActions(outfit),
                    child: Container(
                      width: 220,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Stack(
                        children: [
                          StyledOutfitPreview(outfit: outfit),
                          Positioned(
                            top: 14,
                            right: 14,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.88),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.touch_app_outlined, size: 14),
                                  SizedBox(width: 6),
                                  Text(
                                    'Hold',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildQuickStartCaptureSection() {
    final userId = _authService.user!.uid;
    return StreamBuilder<List<DraftCloth>>(
      stream: _databaseService.getDraftItemsStream(userId),
      builder: (context, draftSnapshot) {
        return StreamBuilder<List<PhotoImportJob>>(
          stream: _databaseService.getPhotoImportJobsStream(userId),
          builder: (context, jobSnapshot) {
            final drafts = draftSnapshot.data ?? const [];
            final jobs = jobSnapshot.data ?? const [];
            final draftCount = drafts.length;
            final ownerImportCount = drafts
                .where(
                  (draft) => draft.source == DraftItemSource.ownerPhotoLibrary,
                )
                .length;
            final activeJobs = jobs
                .where(
                  (job) =>
                      job.status == PhotoImportJobStatus.queued ||
                      job.status == PhotoImportJobStatus.processing,
                )
                .toList(growable: false);
            final latestCompletedOwnerJob = jobs
                .cast<PhotoImportJob?>()
                .firstWhere(
                  (job) =>
                      (job?.mode == PhotoImportJobMode.ownerLibrarySelection ||
                          job?.mode ==
                              PhotoImportJobMode.ownerLibraryAutoScan) &&
                      job?.status == PhotoImportJobStatus.completed &&
                      (job?.sessionId ?? '').isNotEmpty,
                  orElse: () => null,
                );
            final preferences = _homeProfile?.photoImportPreferences;
            final hasImportSetup = preferences != null &&
                (preferences.consentGranted ||
                    preferences.autoCurateIntoAlbumEnabled ||
                    preferences.sourceCollectionId.isNotEmpty ||
                    preferences.sourceCollectionName.isNotEmpty);
            final selectedSourceName =
                preferences?.sourceCollectionName.trim().isNotEmpty == true
                    ? preferences!.sourceCollectionName.trim()
                    : OwnerPhotoImportService.recommendedAlbumName;
            final showCompactStatus = hasImportSetup ||
                draftCount > 0 ||
                activeJobs.isNotEmpty ||
                !_photoImportNudgeDismissed;

            if (!showCompactStatus) {
              return const SizedBox.shrink();
            }

            return Card(
              elevation: 0,
              color: const Color(0xFFF7F2FC),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                hasImportSetup
                                    ? 'Cinduhrella Import'
                                    : 'Set Up Smart Import',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                hasImportSetup
                                    ? draftCount == 0
                                        ? 'New owner photos can flow into pending review automatically while you use the app.'
                                        : '$draftCount item(s) are waiting in review, including $ownerImportCount from personal photos.'
                                    : 'Choose your Cinduhrella photo album once, then let the app keep feeding pending review without constant manual uploads.',
                                style: const TextStyle(
                                  fontSize: 15,
                                  height: 1.45,
                                  color: Color(0xFF5E5870),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!hasImportSetup && !_photoImportNudgeDismissed)
                          IconButton(
                            tooltip: 'Hide for now',
                            onPressed: () {
                              unawaited(_setPhotoImportNudgeDismissed(true));
                            },
                            icon: const Icon(Icons.close_rounded),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        _buildImportStatusChip(
                          icon: Icons.folder_special_outlined,
                          label: hasImportSetup
                              ? selectedSourceName
                              : 'Choose album',
                          accent: const Color(0xFF6D56A8),
                        ),
                        _buildImportStatusChip(
                          icon: Icons.auto_awesome_outlined,
                          label: preferences?.autoCurateIntoAlbumEnabled == true
                              ? 'Auto-curation on'
                              : 'Manual picks',
                          accent: const Color(0xFF3D8B74),
                        ),
                        _buildImportStatusChip(
                          icon: Icons.fact_check_outlined,
                          label: '$draftCount pending',
                          accent: const Color(0xFFCB6A4A),
                        ),
                      ],
                    ),
                    if (activeJobs.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      ...activeJobs.map(
                        (job) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Row(
                              children: [
                                const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    '${job.title}: ${job.processedImages}/${job.totalImages} processed',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      _cancelPhotoImportJob(userId, job),
                                  child: const Text('Cancel'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        FilledButton.icon(
                          onPressed: _openPhotoImportManager,
                          icon: const Icon(Icons.photo_library_outlined),
                          label: Text(
                            hasImportSetup ? 'Manage Import' : 'Set Up Import',
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: draftCount > 0
                              ? () {
                                  _openPendingReview(
                                    sessionId:
                                        latestCompletedOwnerJob?.sessionId,
                                  );
                                }
                              : _showHomeAddActions,
                          icon: Icon(
                            draftCount > 0
                                ? Icons.fact_check_outlined
                                : Icons.add_circle_outline_rounded,
                          ),
                          label: Text(
                            draftCount > 0 ? 'Review Pending' : 'Add Items',
                          ),
                        ),
                      ],
                    ),
                    if (ownerImportCount > 0 || hasImportSetup) ...[
                      const SizedBox(height: 12),
                      Text(
                        hasImportSetup
                            ? 'Nothing is auto-added to your closet. Everything still lands in pending review first.'
                            : 'Tip: use the + button for quick manual adds, bulk capture, or store links.',
                        style: const TextStyle(
                          color: Color(0xFF6C647A),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSavedForLaterSection() {
    final userId = _authService.user!.uid;
    return StreamBuilder<List<DraftCloth>>(
      stream: _databaseService.getSavedForLaterDraftItemsStream(userId),
      builder: (context, snapshot) {
        final drafts = snapshot.data ?? const [];
        if (drafts.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Saved For Later',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Items you parked for later review. Bring them back when you are ready.',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 12),
            ...drafts.map(
              (draft) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 18,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            draft.imageUrl,
                            width: 88,
                            height: 88,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 88,
                              height: 88,
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.checkroom),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (draft.type ?? 'Detected item').trim().isEmpty
                                    ? 'Detected item'
                                    : draft.type!.trim(),
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                [
                                  draft.brand,
                                  draft.color,
                                  draft.size,
                                ]
                                    .whereType<String>()
                                    .where((value) => value.trim().isNotEmpty)
                                    .join(' • '),
                                style: TextStyle(color: Colors.grey.shade700),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Confidence ${(draft.confidence * 100).round()}%',
                                style: const TextStyle(
                                  color: Color(0xFF6D56A8),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                _restoreDraftToReview(userId, draft),
                            icon: const Icon(Icons.replay_rounded),
                            label: const Text('Back To Review'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => _confirmLaterDraft(userId, draft),
                            icon: const Icon(Icons.checkroom_rounded),
                            label: const Text('Add'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          onPressed: () => _dismissLaterDraft(userId, draft),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildImportStatusChip({
    required IconData icon,
    required String label,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: accent),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }

  /// **📌 Home Page Content**
  Widget _buildHomePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(5.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildQuickStartCaptureSection(),
          const SizedBox(height: 20),
          _buildSavedForLaterSection(),
          const SizedBox(height: 20),
          ClosetItemsSection(),
          const SizedBox(height: 5),
          _buildSavedOutfitsSection(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
