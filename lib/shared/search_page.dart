import 'dart:async';
import 'package:cinduhrella/screens/item_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _allItems = [];
  List<Map<String, dynamic>> _filteredItems = [];
  List<String> _searchHistory = [];
  String _dynamicHint = "Search for an item, color, type, room, or storage...";

  int _currentHintIndex = 0;
  Timer? _hintTimer;

  @override
  void initState() {
    super.initState();
    _fetchAllItems();
    _loadSearchHistory();
  }

  @override
  void dispose() {
    _hintTimer?.cancel(); // Cancel the timer when the widget is disposed
    super.dispose();
  }

  /// **⏳ Start cycling hints every 2 seconds**
  void _startHintRotation() {
    // Cancel any existing timer to avoid multiple instances
    _hintTimer?.cancel();

    if (_searchHistory.isNotEmpty) {
      _hintTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
        setState(() {
          _currentHintIndex = (_currentHintIndex + 1) % _searchHistory.length;
          _dynamicHint = _searchHistory[_currentHintIndex];
        });
      });
    }
  }

  Future<void> _fetchAllItems() async {
    String userId = _auth.currentUser!.uid;
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

    setState(() {
      _allItems = itemsList;
      _filteredItems = _allItems;
    });
  }

  void _filterItems(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredItems = _allItems;
      });
      return;
    }

    List<Map<String, dynamic>> filteredList = _allItems.where((item) {
      String brand = item['brand'] ?? '';
      String color = item['color'] ?? '';
      String type = item['type'] ?? '';
      String description = item['description'] ?? '';
      String roomName = item['roomName'] ?? '';
      String storageName = item['storageName'] ?? '';

      return brand.toLowerCase().contains(query.toLowerCase()) ||
          color.toLowerCase().contains(query.toLowerCase()) ||
          type.toLowerCase().contains(query.toLowerCase()) ||
          description.toLowerCase().contains(query.toLowerCase()) ||
          roomName.toLowerCase().contains(query.toLowerCase()) ||
          storageName.toLowerCase().contains(query.toLowerCase());
    }).toList();

    setState(() {
      _filteredItems = filteredList;
    });
  }

  Future<void> _saveSearchToHistory() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList('searchHistory') ?? [];

    if (!history.contains(query)) {
      history.insert(0, query);
      if (history.length > 10) {
        history.removeLast();
      }
      await prefs.setStringList('searchHistory', history);
      setState(() {
        _searchHistory = history;
      });

      // 🔥 Restart hint rotation when search history updates
      _startHintRotation();
    }
  }

  Future<void> _loadSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _searchHistory = prefs.getStringList('searchHistory') ?? [];
    });

    // 🔥 Ensure hint rotation starts if there are saved searches
    _startHintRotation();
  }

  Future<void> _clearSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('searchHistory');
    setState(() {
      _searchHistory = [];
      _dynamicHint = "Search for an item, color, type, room, or storage...";
    });

    // 🔥 Stop hint rotation since history is empty
    _hintTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          onChanged: _filterItems,
          onSubmitted: (_) => _saveSearchToHistory(),
          decoration: InputDecoration(
            hintText: _dynamicHint, // **🔥 Dynamic Hint Text**
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: Colors.grey[200],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: _clearSearchHistory,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_searchHistory.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: const Text(
                "Recent Searches",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            Wrap(
              spacing: 8.0,
              children: _searchHistory.map((query) {
                return GestureDetector(
                  onTap: () {
                    _searchController.text = query;
                    _filterItems(query);
                  },
                  child: Chip(label: Text(query)),
                );
              }).toList(),
            ),
          ],
          Expanded(
            child: _filteredItems.isEmpty
                ? const Center(child: Text("No matching items found."))
                : ListView.builder(
                    itemCount: _filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = _filteredItems[index];
                      return ListTile(
                        leading: Image.network(
                          item['imageUrl'] ?? 'https://via.placeholder.com/150',
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        ),
                        title: Text(safeSubstring(item['description'], 10)),
                        subtitle: Text(
                          truncateText(
                            "${item['color']} ${safeSubstring(item['description'], 7)} by ${item['brand']} is in ${item['roomName']} inside ${item['storageName']}",
                            50,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
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
                    },
                  ),
          ),
        ],
      ),
    );
  }

  /// **🔹 Truncate text if it's too long**
  String truncateText(String text, int maxLength) {
    return text.length > maxLength
        ? "${text.substring(0, maxLength)}..."
        : text;
  }

  /// **🔹 Safely truncate a string to avoid errors**
  String safeSubstring(String text, int length) {
    if (text.isEmpty) return ""; // Handle empty strings
    return text.length > length ? "${text.substring(0, length)}..." : text;
  }
}
