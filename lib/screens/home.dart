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
import 'package:cinduhrella/shared/add_item.dart';
import 'package:cinduhrella/shared/app_drawer.dart';
import 'package:cinduhrella/shared/custom_bar.dart';
import 'package:cinduhrella/shared/styled_outfit_preview.dart';
import 'package:cinduhrella/shared/unassigned_item.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String userName = 'Loading...';
  String profileImageUrl = '';
  final GetIt _getIt = GetIt.instance;
  late AuthService _authService;
  late DatabaseService _databaseService;
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

  @override
  void initState() {
    super.initState();
    _authService = _getIt.get<AuthService>();
    _databaseService = _getIt.get<DatabaseService>();
    _searchHintNotifier = ValueNotifier<String>("Search for an item...");
    _outfitFeedUserFuture = _getUserProfileInformation(_authService.user!.uid);
    _fetchProfileDetails();
    _startHintRotation(); // ✅ Start rotating search hints
  }

  void _startHintRotation() {
    hintTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      currentHintIndex = (currentHintIndex + 1) % _commonSearches.length;
      _searchHintNotifier.value = _commonSearches[currentHintIndex];
    });
  }

  @override
  void dispose() {
    hintTimer?.cancel(); // ✅ Cancel the hint rotation timer
    _searchHintNotifier.dispose();
    super.dispose();
  }

  Future<void> _fetchProfileDetails() async {
    String? uid = _authService.user?.uid;
    if (uid != null) {
      String? fetchedUserName = _authService.user?.displayName ??
          (await _databaseService.getUserProfile(uid: uid))?.userName;
      String? profilePicture = _authService.user?.photoURL ??
          (await _databaseService.getUserProfile(uid: uid))?.profilePictureUrl;

      if (mounted) {
        // ✅ Check before calling setState
        setState(() {
          userName = fetchedUserName ?? 'Unknown User';
          profileImageUrl = profilePicture ?? '';
        });
      }
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
              onPressed: () {
                _showAddItemDialog(
                    context); // ✅ Add Item only on Home & Rooms Page
              },
              child: const Icon(Icons.add),
            )
          : null, // ✅ Hides FAB on other pages (Style, Outfits, Trips)
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
                      job?.mode == PhotoImportJobMode.ownerLibrarySelection &&
                      job?.status == PhotoImportJobStatus.completed &&
                      (job?.sessionId ?? '').isNotEmpty,
                  orElse: () => null,
                );

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Quick-Start Closet",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      draftCount == 0
                          ? "Skip manual item entry. Upload wardrobe shots or import from your personal photos, then confirm only the pieces you want in your closet."
                          : "You have $draftCount draft item(s) pending review, including $ownerImportCount from personal photos. Confirm them to improve planner quality.",
                    ),
                    if (activeJobs.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      ...activeJobs.map(
                        (job) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
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
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const BulkCapturePage(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.camera_outdoor_outlined),
                          label: Text(
                            draftCount == 0
                                ? "Start Bulk Capture"
                                : "Add Wardrobe Photos",
                          ),
                        ),
                        FilledButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const OwnerPhotoImportPage(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.photo_library_outlined),
                          label: const Text("Import My Photos"),
                        ),
                      ],
                    ),
                    if (ownerImportCount > 0) ...[
                      const SizedBox(height: 12),
                      Text(
                        '$ownerImportCount personal-photo draft(s) are waiting in pending review. Nothing is auto-added to your closet.',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                    ],
                    if (latestCompletedOwnerJob?.sessionId != null) ...[
                      const SizedBox(height: 8),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ReviewDetectedItemsPage(
                                sessionId: latestCompletedOwnerJob!.sessionId!,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.fact_check_outlined),
                        label: const Text('Open Latest Pending Review'),
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

  /// **📌 Home Page Content**
  Widget _buildHomePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(5.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildQuickStartCaptureSection(),
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
