import 'package:cinduhrella/shared/image_picker_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'storage_page.dart';

class RoomPage extends StatelessWidget {
  final String roomId;
  final String roomName;

  const RoomPage({super.key, required this.roomId, required this.roomName});

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;
    final userId = FirebaseAuth
        .instance.currentUser!.uid; // Replace with the logged-in user ID

    return Scaffold(
      appBar: AppBar(title: Text(roomName)),
      body: StreamBuilder(
        stream: firestore
            .collection('users/$userId/rooms/$roomId/storages')
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No storages found. Click + to add a new storage!',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          final storages = snapshot.data!.docs;

          return GridView.builder(
            padding: const EdgeInsets.all(8.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8.0,
              mainAxisSpacing: 8.0,
            ),
            itemCount: storages.length,
            itemBuilder: (context, index) {
              final storage = storages[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => StoragePage(
                        storageId: storage.id,
                        storageName: storage['storageName'],
                        roomId: roomId,
                      ),
                    ),
                  );
                },
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(8.0),
                          ),
                          child: Image.network(
                            storage['imageUrl'] ??
                                'https://via.placeholder.com/150',
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          storage['storageName'],
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
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
          _showAddStorageDialog(context, firestore, userId, roomId);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddStorageDialog(BuildContext context, FirebaseFirestore firestore,
      String userId, String roomId) {
    final TextEditingController storageNameController = TextEditingController();
    String? imageUrl; // Store Firebase Storage URL

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add New Storage'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: storageNameController,
                    decoration:
                        const InputDecoration(labelText: 'Storage Name'),
                  ),
                  const SizedBox(height: 16),
                  imageUrl != null
                      ? Image.network(
                          imageUrl!,
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
                            pathType: 'storage',
                            roomId: roomId, // Required for storage images
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
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    final storageName = storageNameController.text.trim();

                    if (storageName.isEmpty || imageUrl == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Storage name and image are required!'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    await firestore
                        .collection('users/$userId/rooms/$roomId/storages')
                        .add({
                      'storageName': storageName,
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
}
