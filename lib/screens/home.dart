import 'dart:async';
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
import 'package:cinduhrella/shared/unassigned_item.dart';
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

  Future<void> _fetchProfileDetails() async {
    String? uid = _authService.user?.uid;
    if (uid != null) {
      String? fetchedUserName = _authService.user?.displayName ??
          (await _databaseService.getUserProfile(uid: uid))?.userName;
      String? profilePicture = _authService.user?.photoURL ??
          (await _databaseService.getUserProfile(uid: uid))?.profilePictureUrl;

      setState(() {
        userName = fetchedUserName ?? 'Unknown User';
        profileImageUrl = profilePicture ?? 'assets/profile_picture.jpg';
      });
    }
  }

  late final List<Widget> _widgetOptions = [
    _buildHomePage(),
    RoomsPage(userId: _authService.user!.uid),
    StylePage(userId: _authService.user!.uid),
    SavedOutfitsPage(userId: _authService.user!.uid),
    TripPage(userId: _authService.user!.uid)
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        userName: userName,
        profileImageUrl: profileImageUrl,
        searchHint: searchHint,
      ),
      drawer: AppDrawer(userName: userName, profileImageUrl: profileImageUrl),
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
          BottomNavigationBarItem(icon: Icon(Icons.checkroom), label: 'Rooms'),
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
              label: 'Trips'), // ✅ New
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

  /// **📌 Home Page Content**
  Widget _buildHomePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UnassignedItemsSection(), // ✅ New Section
          const SizedBox(height: 20),
          GoalTasksSection() // ✅ New Section
        ],
      ),
    );
  }
}
