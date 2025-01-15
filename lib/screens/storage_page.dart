import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StoragePage extends StatelessWidget {
  final String storageId;
  final String storageName;
  final String roomId;

  StoragePage({
    required this.storageId,
    required this.storageName,
    required this.roomId,
  });

  @override
  Widget build(BuildContext context) {
    final userId = "your_user_id"; // Replace with the logged-in user ID
    final _firestore = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(title: Text(storageName)),
      body: StreamBuilder(
        stream: _firestore
            .collection(
                'users/$userId/rooms/$roomId/storages/$storageId/clothes')
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No clothes found in this storage. Click + to add clothes!',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          final clothes = snapshot.data!.docs;

          return ListView.builder(
            itemCount: clothes.length,
            itemBuilder: (context, index) {
              final cloth = clothes[index];
              return ListTile(
                leading: Image.network(
                  cloth['imageUrl'] ?? 'https://via.placeholder.com/150',
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
                title: Text(cloth['brand'] ?? 'Unknown Brand'),
                subtitle: Text(cloth['type'] ?? 'Unknown Type'),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add clothes logic
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
