import 'package:cinduhrella/screens/item_page.dart';
import 'package:cinduhrella/services/database_service.dart';
import 'package:cinduhrella/shared/add_item.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StoragePage extends StatelessWidget {
  final String storageId;
  final String storageName;
  final String roomId;
  final DatabaseService databaseService = DatabaseService();

  StoragePage({
    super.key,
    required this.storageId,
    required this.storageName,
    required this.roomId,
  });
  void _showItemOptions(BuildContext context, FirebaseFirestore firestore,
      String userId, DocumentSnapshot item, String roomId, String storageId) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit Item'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ItemPage(
                        itemId: item.id,
                        roomId: roomId,
                        storageId: storageId,
                      ),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete Item',
                    style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeleteItem(
                      context, firestore, userId, item, roomId, storageId);
                },
              ),
              ListTile(
                leading: const Icon(Icons.move_to_inbox, color: Colors.orange),
                title: const Text('Unassign Item',
                    style: TextStyle(color: Colors.orange)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmUnassignItem(
                      context, firestore, userId, item, roomId, storageId);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmUnassignItem(BuildContext context, FirebaseFirestore firestore,
      String userId, DocumentSnapshot item, String roomId, String storageId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Unassign Item"),
          content: const Text("Are you sure you want to unassign this item?"),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: const Text("Unassign",
                  style: TextStyle(color: Colors.orange)),
              onPressed: () {
                Navigator.pop(context);
                _unassignItem(
                    context, firestore, userId, item, roomId, storageId);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _unassignItem(
      BuildContext context,
      FirebaseFirestore firestore,
      String userId,
      DocumentSnapshot item,
      String roomId,
      String storageId) async {
    DocumentReference itemRef = firestore
        .collection('users/$userId/rooms/$roomId/storages/$storageId/items')
        .doc(item.id);

    DocumentSnapshot itemSnapshot = await itemRef.get();

    if (itemSnapshot.exists) {
      Map<String, dynamic> itemData =
          itemSnapshot.data() as Map<String, dynamic>;

      // Move the item to `users/uid/unassigned`
      await firestore.collection('users/$userId/unassigned').doc(item.id).set({
        ...itemData,
        'unassignedAt': Timestamp.now(),
        'originalRoomId': roomId,
        'originalStorageId': storageId,
      });

      // Delete the item from the original location
      await itemRef.delete();

      // ✅ Show SnackBar with the correct context
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Item moved to Unassigned items."),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  void _confirmDeleteItem(BuildContext context, FirebaseFirestore firestore,
      String userId, DocumentSnapshot item, String roomId, String storageId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Delete Item"),
          content: const Text("Are you sure you want to delete this item?"),
          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: const Text("Delete", style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.pop(context);
                _deleteItem(
                    context, firestore, userId, item, roomId, storageId);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteItem(
      BuildContext context,
      FirebaseFirestore firestore,
      String userId,
      DocumentSnapshot item,
      String roomId,
      String storageId) async {
    DocumentReference itemRef = firestore
        .collection(
          'users/$userId/rooms/$roomId/storages/$storageId/items',
        )
        .doc(item.id);

    DocumentSnapshot itemSnapshot = await itemRef.get();

    if (itemSnapshot.exists) {
      Map<String, dynamic> itemData =
          itemSnapshot.data() as Map<String, dynamic>;

      // Move the item to `users/uid/deleted`
      await firestore.collection('users/$userId/deleted').doc(item.id).set({
        ...itemData,
        'deletedAt': Timestamp.now(),
        'originalRoomId': roomId,
        'originalStorageId': storageId,
      });

      // Delete the item from the original location
      await itemRef.delete();

      // ✅ Show SnackBar with the correct context
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Item moved to deleted items."),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: Text(storageName)),
      body: StreamBuilder(
        stream: firestore
            .collection('users/$userId/rooms/$roomId/storages/$storageId/items')
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No items found in this storage. Click + to add items!',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          final items = snapshot.data!.docs;

          return GridView.builder(
            padding: const EdgeInsets.all(8.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8.0,
              mainAxisSpacing: 8.0,
              childAspectRatio: 0.75,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ItemPage(
                        itemId: item.id,
                        roomId: roomId,
                        storageId: storageId,
                      ),
                    ),
                  );
                },
                onLongPress: () {
                  _showItemOptions(
                      context, firestore, userId, item, roomId, storageId);
                },
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(8.0),
                          ),
                          child: Image.network(
                            item['imageUrl'] ??
                                'https://via.placeholder.com/150',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              item['brand'] ?? 'Unknown Brand',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            Text(
                              item['type'] ?? 'Unknown Type',
                              style: const TextStyle(fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) =>
                AddItemDialog(roomId: roomId, storageId: storageId),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
