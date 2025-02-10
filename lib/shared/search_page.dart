import 'dart:async';
import 'package:cinduhrella/models/user_profile.dart';
import 'package:cinduhrella/screens/item_page.dart';
import 'package:cinduhrella/models/social/post.dart';
import 'package:cinduhrella/services/database_service.dart';
import 'package:cinduhrella/shared/social/profile_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchPage extends StatefulWidget {
  final String searchType; // ✅ "items", "users", or "posts"

  const SearchPage({Key? key, required this.searchType}) : super(key: key);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GetIt _getIt = GetIt.instance;
  late DatabaseService _databaseService;
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> _allResults = [];
  List<dynamic> _filteredResults = [];
  List<String> _searchHistory = [];

  String _dynamicHint = "Search...";
  int _currentHintIndex = 0;
  Timer? _hintTimer;

  @override
  void initState() {
    super.initState();
    _databaseService = _getIt.get<DatabaseService>();
    _fetchResults();
    _loadSearchHistory();
  }

  Future<void> _loadSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _searchHistory = prefs.getStringList('searchHistory') ?? [];
    });

    if (_searchHistory.isNotEmpty) {
      setState(() {
        _dynamicHint =
            _searchHistory.first; // Set initial hint to first search history
      });
    }
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchResults() async {
    String userId = _auth.currentUser!.uid;
    List<dynamic> results = [];

    if (widget.searchType == "items") {
      results = await _fetchItems(userId);
    } else if (widget.searchType == "users") {
      results = await _databaseService.getAllUsers();
    } else if (widget.searchType == "posts") {
      results = await _databaseService.getAllPublicPosts();
    }

    setState(() {
      _allResults = results;
      _filteredResults = results;
    });
  }

  Future<List<Map<String, dynamic>>> _fetchItems(String userId) async {
    List<Map<String, dynamic>> itemsList = [];
    QuerySnapshot roomsSnapshot =
        await _firestore.collection('users/$userId/rooms').get();
    for (var roomDoc in roomsSnapshot.docs) {
      String roomId = roomDoc.id;
      String roomName = roomDoc['roomName'];

      QuerySnapshot storagesSnapshot = await _firestore
          .collection('users/$userId/rooms/$roomId/storages')
          .get();
      for (var storageDoc in storagesSnapshot.docs) {
        String storageId = storageDoc.id;
        String storageName = storageDoc['storageName'];

        QuerySnapshot itemsSnapshot = await _firestore
            .collection('users/$userId/rooms/$roomId/storages/$storageId/items')
            .get();
        for (var itemDoc in itemsSnapshot.docs) {
          Map<String, dynamic> itemData =
              itemDoc.data() as Map<String, dynamic>;
          itemData['itemId'] = itemDoc.id;
          itemData['roomId'] = roomId;
          itemData['roomName'] = roomName;
          itemData['storageId'] = storageId;
          itemData['storageName'] = storageName;

          itemsList.add(itemData);
        }
      }
    }
    return itemsList;
  }

  void _filterResults(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredResults = _allResults;
      });
      return;
    }

    List<dynamic> filteredList = _allResults.where((result) {
      if (widget.searchType == "items") {
        return result['description']
                .toLowerCase()
                .contains(query.toLowerCase()) ||
            result['brand'].toLowerCase().contains(query.toLowerCase()) ||
            result['color'].toLowerCase().contains(query.toLowerCase());
      } else if (widget.searchType == "users") {
        return (result as UserProfile)
                .fullName!
                .toLowerCase()
                .contains(query.toLowerCase()) ||
            result.userName!.toLowerCase().contains(query.toLowerCase());
      } else if (widget.searchType == "posts") {
        return (result as Post)
            .title!
            .toLowerCase()
            .contains(query.toLowerCase());
      }
      return false;
    }).toList();

    setState(() {
      _filteredResults = filteredList;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          onChanged: _filterResults,
          decoration: InputDecoration(
            hintText: _dynamicHint,
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: Colors.grey[200],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ),
      body: _filteredResults.isEmpty
          ? const Center(child: Text("No results found."))
          : ListView.builder(
              itemCount: _filteredResults.length,
              itemBuilder: (context, index) {
                final result = _filteredResults[index];

                if (widget.searchType == "items") {
                  return _buildItemTile(result);
                } else if (widget.searchType == "users") {
                  return _buildUserTile(result);
                } else if (widget.searchType == "posts") {
                  return _buildPostTile(result);
                }
                return Container();
              },
            ),
    );
  }

  Widget _buildItemTile(Map<String, dynamic> item) {
    return ListTile(
      leading: Image.network(
        item['imageUrl'] ?? 'https://via.placeholder.com/150',
        width: 50,
        height: 50,
        fit: BoxFit.cover,
      ),
      title: Text(item['description'] ?? "Unknown Item"),
      subtitle: Text("${item['brand']} - ${item['color']}"),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ItemPage(
              itemId: item['itemId'],
              roomId: item['roomId'],
              storageId: item['storageId'],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserTile(UserProfile user) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: NetworkImage(user.profilePictureUrl ??
            "https://example.com/default-profile.png"),
      ),
      title: Text(user.fullName ?? "Unknown User"),
      subtitle: Text("@${user.userName}"),
      onTap: () async {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfilePage(
              user: user,
              currentUserId: _auth.currentUser!.uid,
              isOwnProfile: user.uid == _auth.currentUser!.uid,
            ),
          ),
        );
      },
    );
  }

  Widget _buildPostTile(Post post) {
    return ListTile(
      title: Text(post.title ?? "Untitled"),
      subtitle: Text(post.description ?? "No description"),
      onTap: () {
        // Implement navigation to post details if needed
      },
    );
  }
}
