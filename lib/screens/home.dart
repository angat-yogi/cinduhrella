import 'dart:async';
import 'package:cinduhrella/models/cloth.dart';
import 'package:cinduhrella/models/styled_outfit.dart';
import 'package:cinduhrella/models/user_profile.dart';
import 'package:cinduhrella/screens/outfit_feed.dart';
import 'package:cinduhrella/screens/room_page.dart';
import 'package:cinduhrella/screens/rooms_page.dart';
import 'package:cinduhrella/screens/saved_outfit.dart';
import 'package:cinduhrella/screens/style_page.dart';
import 'package:cinduhrella/screens/trip_page.dart';
import 'package:cinduhrella/services/auth_service.dart';
import 'package:cinduhrella/services/database_service.dart';
import 'package:cinduhrella/shared/add_item.dart';
import 'package:cinduhrella/shared/app_drawer.dart';
import 'package:cinduhrella/shared/custom_bar.dart';
import 'package:cinduhrella/shared/goal_task.dart';
import 'package:cinduhrella/shared/image_picker_dialog.dart';
import 'package:cinduhrella/shared/outfit_widget.dart';
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
  String searchHint = "Search for an item...";
  int currentHintIndex = 0;
  Timer? hintTimer;

  @override
  void initState() {
    super.initState();
    _authService = _getIt.get<AuthService>();
    _databaseService = _getIt.get<DatabaseService>();
    _fetchProfileDetails();
    _startHintRotation(); // ✅ Start rotating search hints
  }

  void _startHintRotation() {
    hintTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      setState(() {
        currentHintIndex = (currentHintIndex + 1) % _commonSearches.length;
        searchHint = _commonSearches[currentHintIndex];
      });
    });
  }

  @override
  void dispose() {
    hintTimer?.cancel(); // ✅ Cancel the hint rotation timer
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
          profileImageUrl = profilePicture ?? 'assets/profile_picture.jpg';
        });
      }
    }
  }

  void _showAddRoomDialog(
      BuildContext context, FirebaseFirestore firestore, String userId) {
    final TextEditingController roomNameController = TextEditingController();
    String? imageUrl; // Store Firebase Storage URL

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add New Room'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: roomNameController,
                    decoration: const InputDecoration(labelText: 'Room Name'),
                  ),
                  const SizedBox(height: 16),
                  imageUrl != null
                      ? Image.network(
                          imageUrl!, // Display the uploaded image
                          width: 150,
                          height: 150,
                          fit: BoxFit.cover,
                        )
                      : const SizedBox.shrink(),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) {
                          return ImagePickerDialog(
                            userId: userId,
                            pathType: 'room',
                            onImagePicked: (String uploadedImageUrl) {
                              setState(() {
                                imageUrl =
                                    uploadedImageUrl; // Store Firebase Storage URL
                              });
                            },
                          );
                        },
                      );
                    },
                    child: const Text('Pick Image'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    final roomName = roomNameController.text.trim();

                    if (roomName.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Room name cannot be empty!'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    if (imageUrl == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please select an image!'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    // Save room details to Firestore with Firebase Storage URL
                    await firestore.collection('users/$userId/rooms').add({
                      'roomName': roomName,
                      'imageUrl': imageUrl, // Store Firebase Storage URL
                    });

                    Navigator.of(context).pop();
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildRoomsSection() {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    String userId = _authService.user!.uid;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Your Rooms",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.add, size: 24, color: Colors.blue),
              onPressed: () {
                _showAddRoomDialog(context, firestore, userId);
              },
            ),
          ],
        ),
        const SizedBox(height: 10),
        const SizedBox(height: 10),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users/$userId/rooms')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Text(
                'No rooms found. Add a new room!',
                style: TextStyle(fontSize: 16),
              );
            }

            final rooms = snapshot.data!.docs;

            return SizedBox(
              height: 150, // Adjusted for horizontal scrolling
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: rooms.length,
                itemBuilder: (context, index) {
                  final room = rooms[index];
                  final imageUrl = room['imageUrl'] ?? '';
                  final roomId = room.id;
                  final roomName = room['roomName'];

                  return GestureDetector(
                    onTap: () {
                      // Navigate to RoomPage when a room is clicked
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              RoomPage(roomId: roomId, roomName: roomName),
                        ),
                      );
                    },
                    child: Container(
                      width: 120,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.0),
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.3),
                            spreadRadius: 2,
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(8.0)),
                              child: imageUrl.isNotEmpty
                                  ? Image.network(
                                      imageUrl,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                    )
                                  : Image.asset(
                                      'assets/placeholder.png',
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                    ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              roomName,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.bold),
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

  late final List<Widget> _widgetOptions = [
    _buildHomePage(),
    StylePage(userId: _authService.user!.uid),
    SavedOutfitsPage(userId: _authService.user!.uid),
    TripPage(userId: _authService.user!.uid),
    FutureBuilder<UserProfile>(
      future: _getUserProfileInformation(_authService.user!.uid),
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
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _selectedIndex == 4
          ? null
          : CustomAppBar(
              userName: userName,
              profileImageUrl: profileImageUrl,
              searchHint: searchHint,
            ),
      drawer: _selectedIndex == 4
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
              icon: Icon(Icons.shopping_bag), label: 'Style'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Outfits'),
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
              height: 250, // Adjusted for outfit display
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: outfits.length,
                itemBuilder: (context, index) {
                  final outfit = outfits[index];

                  // Get the correct images from the outfit
                  String? topWearImage = outfit.clothes
                      .firstWhere((c) => c.type == "Top Wear",
                          orElse: () => Cloth.empty())
                      .imageUrl;

                  String? bottomWearImage = outfit.clothes
                      .firstWhere((c) => c.type == "Bottom Wear",
                          orElse: () => Cloth.empty())
                      .imageUrl;

                  String? leftAccessoryImage = outfit.clothes
                      .firstWhere((c) => c.type == "Accessories",
                          orElse: () => Cloth.empty())
                      .imageUrl;

                  String? rightAccessoryImage = outfit.clothes
                      .lastWhere((c) => c.type == "Others",
                          orElse: () => Cloth.empty())
                      .imageUrl;

                  return GestureDetector(
                    onTap: () {
                      // Show styled outfit details when tapped
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              SavedOutfitsPage(userId: userId),
                        ),
                      );
                    },
                    child: Container(
                      width: 180,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.0),
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.3),
                            spreadRadius: 2,
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Styled Outfit Visualization
                          StyledOutfitWidget(
                            outfitName: outfit.name,
                            topWearImage: topWearImage ??
                                'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcROe35OsA_R0tjBDYrR34n_yCOZN9tmeGcJYA&s', // Placeholder if missing
                            bottomWearImage: bottomWearImage ??
                                'https://res.cloudinary.com/hamstech/images/w_440,h_660/f_auto,q_auto/v1628494598/Hamstech%20App/Culottes/Culottes.jpg?_i=AA',
                            leftAccessoryImage: leftAccessoryImage ??
                                'https://res.cloudinary.com/hamstech/images/w_440,h_660/f_auto,q_auto/v1628494598/Hamstech%20App/Culottes/Culottes.jpg?_i=AA',
                            rightAccessoryImage: rightAccessoryImage ??
                                'https://res.cloudinary.com/hamstech/images/w_440,h_660/f_auto,q_auto/v1628494598/Hamstech%20App/Culottes/Culottes.jpg?_i=AA',
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

  /// **📌 Home Page Content**
  Widget _buildHomePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(5.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UnassignedItemsSection(), // ✅ New Section
          const SizedBox(height: 20),
          _buildRoomsSection(), // ✅ Updated Section
          // GoalTasksSection() // ✅ New Section
          const SizedBox(height: 5),
          _buildSavedOutfitsSection(),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}
