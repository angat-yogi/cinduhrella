import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RoomPage extends StatelessWidget {
  final String roomId;

  RoomPage({required this.roomId});

  @override
  Widget build(BuildContext context) {
    final userId = "your_user_id"; // Replace with logged-in user ID
    final _firestore = FirebaseFirestore.instance;

    return Scaffold(
      appBar: AppBar(title: Text('Storages')),
      body: StreamBuilder(
        stream: _firestore
            .collection('users/$userId/rooms/$roomId/storages')
            .snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          return ListView(
            children: snapshot.data!.docs.map((storage) {
              return ListTile(
                title: Text(storage['storageName']),
                onTap: () {
                  // Navigate to storage items page
                },
              );
            }).toList(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Add storage logic
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
