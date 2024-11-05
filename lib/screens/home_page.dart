import 'package:cinduhrella/screens/closet_page.dart';
import 'package:cinduhrella/screens/feed_page.dart';
import 'package:cinduhrella/screens/style_page.dart';
import 'package:cinduhrella/services/alert_service.dart';
import 'package:cinduhrella/services/auth_service.dart';
import 'package:cinduhrella/services/database_service.dart';
import 'package:cinduhrella/services/navigation_service.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
   String userName = 'Loading...'; // User's name
   String profileImageUrl = ''; // Placeholder profile image URL
  final GetIt _getIt = GetIt.instance;
  late AuthService _authService;
  late NavigationService _navigationService;
  late AlertService _alertService;
  late DatabaseService _databaseService;
  int _selectedIndex = 0;

@override
  void initState(){
  super.initState();
  _authService=_getIt.get<AuthService>();
  _navigationService=_getIt<NavigationService>();
  _alertService=_getIt<AlertService>();
  _databaseService=_getIt<DatabaseService>();
  _fetchProfileDetails();
  }

  Future<void> _fetchProfileDetails() async {
  String? uid = _authService.user?.uid; // Ensure you have the user's UID from auth
  if (uid != null) {
    String? fetchedUserName = _authService.user?.displayName??'User not found';
    String? profilePicture =  _authService.user?.photoURL??'assets/profile_picture.jpg'; // Ensure this method fetches the profile picture URL
    
    setState(() {
      userName = fetchedUserName ; 
      profileImageUrl = profilePicture; 
    });
  }
}



  static final List<Widget> _widgetOptions = <Widget>[
     const FeedPage(), // Replace this with your feed page widget
    const ClosetPage(), // Replace this with your messages page widget
     const StylePage(), // Replace this with your groups page widget
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      drawer: _buildDrawer(), // Add the Drawer here
      body: IndexedStack(
        index: _selectedIndex,
        children: _widgetOptions,
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.checkroom),
            label: 'Closet',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag),
            label: 'Style',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: _onItemTapped,
      ),
    );
  }

PreferredSizeWidget _buildAppBar() {
  return AppBar(
    toolbarHeight: 100,
    backgroundColor: Colors.white,
    elevation: 1,
    automaticallyImplyLeading: false, // Hide the default back button
    title: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10), // Add some top padding
        Row(
          crossAxisAlignment: CrossAxisAlignment.center, // Center the profile picture and name
          children: [
            // Use a Builder to get the correct context
            Builder(
              builder: (context) => GestureDetector(
                onTap: () {
                  // Open the drawer when the profile image is tapped
                  Scaffold.of(context).openDrawer();
                },
                child: CircleAvatar(
                  radius: 25,
                  backgroundImage: NetworkImage(profileImageUrl),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded( // Use Expanded to avoid overflow
              child: Text(
                'Hello, $userName',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                overflow: TextOverflow.ellipsis, // Handle overflow
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Search Bar
        TextField(
          decoration: InputDecoration(
            hintText: 'Search...',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: Colors.grey[200],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 0),
          ),
        ),
      ],
    ),
  );
}

  // Drawer with Settings, App Version, and Log Out
  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Colors.blue,
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: NetworkImage(profileImageUrl),
                ),
                const SizedBox(height: 10),
                Text(
                  userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              // Handle settings tap
            },
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('App Version'),
            subtitle: const Text('v1.0.0'),
            onTap: () {
              // Handle app version tap
            },
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Log Out'),
            onTap: () async {
              bool logOutResult= await _authService.logout();
              if(logOutResult){
                _navigationService.pushReplacementNamed("/login");
                _alertService.showToast(text: "Sad to see you leave!", icon: Icons.done);

              }
              else{

              }
            },
          ),
        ],
      ),
    );
  }
}
