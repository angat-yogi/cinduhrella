import 'package:cinduhrella/shared/image_picker_dialog.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'room_page.dart';

class RoomsPage extends StatelessWidget {
  final String userId; // Logged-in user's ID

  const RoomsPage({required this.userId, super.key});

  @override
  Widget build(BuildContext context) {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rooms'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestore.collection('users/$userId/rooms').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No rooms found. Click + to add a new room!',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          final rooms = snapshot.data!.docs;

          return GridView.builder(
            padding: const EdgeInsets.all(8.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, // Two items in a row
              crossAxisSpacing: 8.0,
              mainAxisSpacing: 8.0,
            ),
            itemCount: rooms.length,
            itemBuilder: (context, index) {
              final room = rooms[index];
              final imageUrl =
                  room['imageUrl'] ?? ''; // Get the Firebase Storage URL

              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RoomPage(
                        roomId: room.id,
                        roomName: room['roomName'],
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
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(8.0),
                          ),
                          child: imageUrl.isNotEmpty
                              ? Image.network(
                                  imageUrl, // Load image from Firebase Storage
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  loadingBuilder: (context, child, progress) {
                                    return progress == null
                                        ? child
                                        : const Center(
                                            child: CircularProgressIndicator());
                                  },
                                  errorBuilder: (context, error, stackTrace) =>
                                      Image.asset(
                                    'assets/placeholder.png', // Fallback image
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                  ),
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
                          room['roomName'],
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
          _showAddRoomDialog(context, firestore, userId);
        },
        child: const Icon(Icons.add),
      ),
    );
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
}
