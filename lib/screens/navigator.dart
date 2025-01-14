import 'package:cinduhrella/screens/home.dart';
import 'package:cinduhrella/screens/rooms_page.dart';
import 'package:cinduhrella/screens/settings.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NavigatorScreen extends StatefulWidget {
  @override
  _NavigatorScreenState createState() => _NavigatorScreenState();
}

class _NavigatorScreenState extends State<NavigatorScreen> {
  int _currentIndex = 0;
  String? userId; // To store the Firebase user ID
  List<Widget> _pages = []; // Initialize as an empty list

  @override
  void initState() {
    super.initState();
    fetchUserId(); // Fetch user ID from FirebaseAuth
  }

  // Fetch the user ID from Firebase Authentication
  void fetchUserId() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        setState(() {
          userId = user.uid; // Get the user ID
          // Initialize pages after fetching the user ID
          _pages = [
            HomePage(), // Your HomePage widget
            RoomsPage(userId: userId!), // Pass the userId to RoomsPage
            SettingsPage(), // Your SettingsPage widget
          ];
        });
      } else {
        // If no user is logged in, navigate to login screen
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      // Handle error
      print("Error fetching user ID: $e");
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Show a loading screen while fetching the user ID or initializing pages
    if (userId == null || _pages.isEmpty) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.room),
            label: 'Rooms',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
