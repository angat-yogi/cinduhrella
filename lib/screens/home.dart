import 'dart:convert';

import 'package:cinduhrella/models/to_dos/custom_task.dart';
import 'package:cinduhrella/models/to_dos/goal.dart';
import 'package:cinduhrella/models/to_dos/wishlist.dart';
import 'package:cinduhrella/screens/rooms_page.dart';
import 'package:cinduhrella/screens/style_page.dart'; // Replace with your StylePage
import 'package:cinduhrella/services/alert_service.dart';
import 'package:cinduhrella/services/auth_service.dart';
import 'package:cinduhrella/services/database_service.dart';
import 'package:cinduhrella/services/navigation_service.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:crypto/crypto.dart';

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
  late NavigationService _navigationService;
  late AlertService _alertService;
  late DatabaseService _databaseService;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _authService = _getIt.get<AuthService>();
    _navigationService = _getIt.get<NavigationService>();
    _alertService = _getIt.get<AlertService>();
    _databaseService = _getIt.get<DatabaseService>();
    _fetchProfileDetails();
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
      drawer: _buildDrawer(),
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
            label: 'Rooms',
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
      automaticallyImplyLeading: false,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Builder(
                builder: (context) => GestureDetector(
                  onTap: () {
                    Scaffold.of(context).openDrawer();
                  },
                  child: CircleAvatar(
                    radius: 25,
                    backgroundImage: NetworkImage(profileImageUrl),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Hello, $userName',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
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

  Widget _buildHomePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Goals in Progress',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.add, color: Colors.blue),
                onPressed: _addGoal,
              ),
            ],
          ),
          const SizedBox(height: 10),
          StreamBuilder<List<Goal>>(
            stream: _databaseService.getGoals(_authService.user!.uid),
            builder: (context, snapshot) {
              // if (!snapshot.hasData) return const CircularProgressIndicator();
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                    child:
                        CircularProgressIndicator()); // Show loading indicator
              } else if (snapshot.hasData) {
                final goals = snapshot.data!;
                return SizedBox(
                  height: 150,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: goals.length,
                    itemBuilder: (context, index) {
                      final goal = goals[index];
                      return Card(
                        child: Container(
                          width: 200,
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(goal.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              const SizedBox(height: 5),
                              LinearProgressIndicator(
                                value: goal.progress / 100,
                              ),
                              Text('${goal.progress}% complete'),
                              IconButton(
                                icon: const Icon(Icons.add, color: Colors.blue),
                                onPressed: () => _addTaskToGoal(goal.id!),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              } else {
                return Text('No data available');
              }
            },
          ),
          const SizedBox(height: 20),
          const Text(
            'Wishlist Highlights',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          StreamBuilder<List<Wishlist>>(
            stream: _databaseService.getWishlist(_authService.user!.uid),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const CircularProgressIndicator();
              final wishlist = snapshot.data!;
              if (wishlist.isEmpty) {
                return const Text('No items in wishlist.');
              }
              final nextItem = wishlist.first;
              return ListTile(
                leading: Image.network(nextItem.imageUrl),
                title: Text(nextItem.name),
                subtitle: Text('Unlock in ${nextItem.pointsNeeded} points'),
              );
            },
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tasks for Today',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.add, color: Colors.blue),
                onPressed: () => _addTaskToGoal(null), // Add to general tasks
              ),
            ],
          ),
          StreamBuilder<List<CustomTask>>(
            stream: _databaseService.getTasks(_authService.user!.uid),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const CircularProgressIndicator();
              final tasks = snapshot.data!;
              return Column(
                children: tasks.map((task) {
                  return CheckboxListTile(
                    title: Text(task.name),
                    value: task.completed,
                    onChanged: (newValue) {
                      final updatedTask = CustomTask(
                        id: task.id,
                        name: task.name,
                        completed: newValue!,
                        goalId: task.goalId,
                      );
                      _databaseService.updateTask(
                          _authService.user!.uid, task.id!, updatedTask);
                    },
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  void _addGoal() {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController nameController = TextEditingController();
        return AlertDialog(
          title: const Text('Add Goal'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(hintText: 'Goal Name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final goalId = _generateGoalId();
                final goal =
                    Goal(id: goalId, name: nameController.text, progress: 0);
                _databaseService.addGoal(_authService.user!.uid, goal);
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _addTaskToGoal(String? goalId) {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController taskController = TextEditingController();
        return AlertDialog(
          title: const Text('Add Task'),
          content: TextField(
            controller: taskController,
            decoration: const InputDecoration(hintText: 'Task Name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                final task = CustomTask(
                    name: taskController.text,
                    completed: false,
                    goalId: goalId);
                if (goalId != null) {
                  _databaseService.addTaskToGoal(
                      _authService.user!.uid, goalId, task);
                } else {
                  _databaseService.addTask(_authService.user!.uid, task);
                }
                Navigator.pop(context);
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

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
              _navigationService.pushNamed('/settings');
            },
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('App Version'),
            subtitle: const Text('v1.0.0'),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Log Out'),
            onTap: () async {
              bool logOutResult = await _authService.logout();
              if (logOutResult) {
                _navigationService.pushReplacementNamed("/login");
                _alertService.showToast(
                    text: "Sad to see you leave!", icon: Icons.done);
              }
            },
          ),
        ],
      ),
    );
  }

  String _generateGoalId() {
    final userIdFor = _authService.user!.uid;
    final userIdHash = sha256.convert(utf8.encode(userIdFor)).toString();
    return '$userIdHash-${DateTime.now().millisecondsSinceEpoch}';
  }
}
