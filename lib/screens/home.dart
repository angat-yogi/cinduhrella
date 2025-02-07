import 'package:cinduhrella/screens/rooms_page.dart';
import 'package:cinduhrella/screens/saved_outfit.dart';
import 'package:cinduhrella/screens/style_page.dart';
import 'package:cinduhrella/services/alert_service.dart';
import 'package:cinduhrella/services/auth_service.dart';
import 'package:cinduhrella/services/database_service.dart';
import 'package:cinduhrella/services/navigation_service.dart';
import 'package:cinduhrella/shared/image_picker_dialog.dart';
import 'package:cinduhrella/shared/search_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:cinduhrella/models/to_dos/custom_task.dart';
import 'package:cinduhrella/models/to_dos/goal.dart';
import 'package:cinduhrella/models/to_dos/wishlist.dart';

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
    SavedOutfitsPage(userId: _authService.user!.uid),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddItemDialog(context);
        },
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.checkroom), label: 'Rooms'),
          BottomNavigationBarItem(
              icon: Icon(Icons.shopping_bag), label: 'Style'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Outfits'),
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
    final TextEditingController descriptionController = TextEditingController();
    String? selectedSize;
    String? selectedType;
    String? selectedColor;
    String? selectedBrand;
    String? imageUrl;

    final List<String> sizes = ["XS", "S", "M", "L", "XL"];
    final List<String> types = [
      "Top Wear",
      "Bottom Wear",
      "Accessories",
      "Others"
    ];
    final List<String> brands = [
      "Nike",
      "Adidas",
      "Zara",
      "Gucci",
      "H&M",
      "Louis Vuitton",
      "Prada",
      "Others"
    ];
    final List<String> colors = [
      "Black",
      "White",
      "Blue",
      "Red",
      "Green",
      "Yellow",
      "Pink",
      "Gray"
    ];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add New Item'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Brand Dropdown
                    DropdownButtonFormField<String>(
                      value: selectedBrand,
                      decoration: const InputDecoration(labelText: "Brand"),
                      items: brands.map((size) {
                        return DropdownMenuItem(value: size, child: Text(size));
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          selectedBrand = newValue!;
                        });
                      },
                    ),

                    // Size Dropdown
                    DropdownButtonFormField<String>(
                      value: selectedSize,
                      decoration: const InputDecoration(labelText: "Size"),
                      items: sizes.map((size) {
                        return DropdownMenuItem(value: size, child: Text(size));
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          selectedSize = newValue!;
                        });
                      },
                    ),

                    // Type Dropdown
                    DropdownButtonFormField<String>(
                      value: selectedType,
                      decoration: const InputDecoration(labelText: "Type"),
                      items: types.map((type) {
                        return DropdownMenuItem(value: type, child: Text(type));
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          selectedType = newValue!;
                        });
                      },
                    ),

                    // Color Dropdown
                    DropdownButtonFormField<String>(
                      value: selectedColor,
                      decoration: const InputDecoration(labelText: "Color"),
                      items: colors.map((color) {
                        return DropdownMenuItem(
                            value: color, child: Text(color));
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          selectedColor = newValue!;
                        });
                      },
                    ),

                    // Description
                    TextField(
                      controller: descriptionController,
                      decoration:
                          const InputDecoration(labelText: 'Description'),
                      maxLines: 3,
                    ),

                    const SizedBox(height: 16),
                    imageUrl != null
                        ? Image.network(imageUrl!,
                            width: 150, height: 150, fit: BoxFit.cover)
                        : const SizedBox.shrink(),
                    const SizedBox(height: 16),

                    // Image Picker Button
                    ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return ImagePickerDialog(
                              userId: _authService.user!.uid,
                              pathType: 'unassigned',
                              onImagePicked: (String uploadedImageUrl) {
                                setState(() {
                                  imageUrl = uploadedImageUrl;
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
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    if (selectedBrand == null ||
                        selectedSize == null ||
                        selectedType == null ||
                        selectedColor == null ||
                        imageUrl == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text('All fields and an image are required!'),
                            backgroundColor: Colors.red),
                      );
                      return;
                    }

                    await FirebaseFirestore.instance
                        .collection(
                            'users/${_authService.user!.uid}/unassigned')
                        .add({
                      'brand': selectedBrand,
                      'size': selectedSize,
                      'type': selectedType,
                      'color': selectedColor,
                      'description': descriptionController.text.trim(),
                      'imageUrl': imageUrl,
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

  /// **📌 App Bar with Search**
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
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const SearchPage()));
            },
            readOnly: true,
            decoration: InputDecoration(
              hintText: 'Search for an item...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.grey[200],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(30),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// **📌 Home Page Content**
  Widget _buildHomePage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildUnassignedItemsSection(), // ✅ New Section
          const SizedBox(height: 20),
          _buildGoalsSection(),
          _buildWishlistSection(),
          _buildTasksSection(),
        ],
      ),
    );
  }

  Widget _buildUnassignedItemsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Unassigned Items',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users/${_authService.user!.uid}/unassigned')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Text("No unassigned items found.");
            }

            final items = snapshot.data!.docs;
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final itemData = item.data()
                    as Map<String, dynamic>; // ✅ Ensure it's cast correctly

                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: itemData['imageUrl'] != null
                        ? Image.network(itemData['imageUrl'],
                            width: 50, height: 50)
                        : const Icon(Icons.image, size: 50),
                    title: Text(itemData['brand'] ?? "Unknown Item"),
                    subtitle: Text(itemData['type'] ?? "No Type"),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _assignItemDialog(
                          context, item.id, itemData), // ✅ Pass full data
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  /// **📌 Assign Item to Room/Storage Dialog**
  void _assignItemDialog(
      BuildContext context, String itemId, Map<String, dynamic> itemData) {
    String? selectedRoom;
    String? selectedStorage;
    List<Map<String, dynamic>> rooms = [];
    List<Map<String, dynamic>> storages = [];
    bool isLoadingRooms = true; // ✅ Track loading status

    /// **📌 Fetch Storages when a Room is Selected**
    void fetchStorages(String roomId, Function(void Function()) updateDialog) {
      print("Fetching storages for room: $roomId");
      _databaseService
          .getStorages(_authService.user!.uid, roomId)
          .listen((storageList) {
        updateDialog(() {
          storages = storageList;
        });
      });
    }

    /// **📌 Shows the Dialog Only After Data is Ready**
    void _showDialog() {
      showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text('Assign Item'),
                content: isLoadingRooms
                    ? const Center(
                        child: CircularProgressIndicator()) // ✅ Show loader
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Room Dropdown
                          DropdownButtonFormField<String>(
                            value: selectedRoom,
                            decoration:
                                const InputDecoration(labelText: "Select Room"),
                            items: rooms.map((room) {
                              return DropdownMenuItem(
                                value: room['roomId']?.toString() ?? '',
                                child: Text(room['roomName']?.toString() ??
                                    'Unknown Room'),
                              );
                            }).toList(),
                            onChanged: (newValue) {
                              setState(() {
                                selectedRoom = newValue;
                                selectedStorage =
                                    null; // Reset storage selection
                                if (newValue != null) {
                                  fetchStorages(newValue, setState);
                                }
                              });
                            },
                          ),

                          // Storage Dropdown (optional)
                          DropdownButtonFormField<String>(
                            value: selectedStorage,
                            decoration: const InputDecoration(
                                labelText: "Select Storage (Optional)"),
                            items: storages.map((storage) {
                              return DropdownMenuItem(
                                value: storage['storageId']?.toString() ?? '',
                                child: Text(
                                    storage['storageName']?.toString() ??
                                        'Unknown Storage'),
                              );
                            }).toList(),
                            onChanged: (newValue) {
                              setState(() {
                                selectedStorage = newValue;
                              });
                            },
                          ),
                        ],
                      ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () async {
                      if (selectedRoom == null || selectedRoom!.isEmpty) {
                        _alertService.showToast(
                          text: "Please select at least a room!",
                          icon: Icons.error,
                        );
                        return;
                      }

                      await _databaseService.assignItemToRoomStorage(
                        _authService.user!.uid,
                        itemId,
                        selectedRoom!,
                        selectedStorage ?? '',
                        itemData,
                      );

                      Navigator.pop(context);
                    },
                    child: const Text('Assign'),
                  ),
                ],
              );
            },
          );
        },
      );
    }

    /// **📌 Fetch Rooms Before Opening the Dialog**
    void fetchRoomsAndShowDialog() {
      _databaseService.getRooms(_authService.user!.uid).listen((roomList) {
        rooms = roomList;
        isLoadingRooms = false; // ✅ Set loading to false
        if (context.mounted) {
          _showDialog(); // ✅ Open dialog only after rooms are fetched
        }
      });
    }

    fetchRoomsAndShowDialog(); // ✅ Fetch rooms first, then show dialog
  }

  /// **📌 Goals Section**
  Widget _buildGoalsSection() {
    return Column(
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
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    goal.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon:
                                      const Icon(Icons.add, color: Colors.blue),
                                  onPressed: () => _addTaskToGoal(goal.id!),
                                ),
                              ],
                            ),
                            const SizedBox(height: 5),
                            LinearProgressIndicator(value: goal.progress / 100),
                            Text('${goal.progress}% complete'),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            } else {
              return const Text('No goals found.');
            }
          },
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  /// **📌 Wishlist Section**
  Widget _buildWishlistSection() {
    return StreamBuilder<List<Wishlist>>(
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
    );
  }

  /// **📌 Tasks Section**
  Widget _buildTasksSection() {
    return StreamBuilder<List<CustomTask>>(
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
