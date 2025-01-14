import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HomePage extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final userId = "your_user_id"; // Replace with logged-in user ID

    return Scaffold(
      appBar: AppBar(
        title: Text('Your Rooms'),
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(50.0),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search clothes...',
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (query) {
                // Handle search logic
              },
            ),
          ),
        ),
      ),
      body: StreamBuilder(
        stream: _firestore.collection('users/$userId/rooms').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          return ListView(
            children: snapshot.data!.docs.map((room) {
              return ListTile(
                title: Text(room['roomName']),
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/room',
                    arguments: room.id,
                  );
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
