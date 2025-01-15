import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StylePage extends StatelessWidget {
  final String userId; // Pass the logged-in user ID

  const StylePage({required this.userId, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Style Your Clothes'),
        backgroundColor: Colors.blue,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('users/$userId/clothes')
            .snapshots(), // Fetch user's clothes
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final clothes = snapshot.data!.docs;

          if (clothes.isEmpty) {
            return const Center(
              child: Text(
                'No clothes available. Add some clothes to your closet!',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            itemCount: clothes.length,
            itemBuilder: (context, index) {
              final cloth = clothes[index];
              return _buildClothCard(cloth);
            },
          );
        },
      ),
    );
  }

  Widget _buildClothCard(DocumentSnapshot cloth) {
    String brand = cloth['brand'] ?? 'Unknown Brand';
    String type = cloth['type'] ?? 'Unknown Type';
    String imageUrl = cloth['imageUrl'] ?? '';
    bool liked = cloth['liked'] ?? false;

    return Card(
      elevation: 3,
      margin: const EdgeInsets.all(8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image of the cloth
          if (imageUrl.isNotEmpty)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(10),
              ),
              child: Image.network(
                imageUrl,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  brand,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  type,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      liked ? 'You like this!' : 'Do you like this?',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: liked ? Colors.green : Colors.grey,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.thumb_up, color: Colors.green),
                          onPressed: () => _updateLikeStatus(cloth.id, true),
                        ),
                        IconButton(
                          icon: const Icon(Icons.thumb_down,
                              color: Colors.redAccent),
                          onPressed: () => _updateLikeStatus(cloth.id, false),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _updateLikeStatus(String clothId, bool liked) {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    _firestore
        .collection('users/$userId/clothes')
        .doc(clothId)
        .update({'liked': liked}).then((_) {
      print("Cloth updated successfully");
    }).catchError((error) {
      print("Failed to update cloth: $error");
    });
  }
}
