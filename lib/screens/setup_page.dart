import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SetupPage extends StatefulWidget {
  @override
  _SetupPageState createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  final TextEditingController roomController = TextEditingController();
  final List<Map<String, dynamic>> rooms = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void addRoom() {
    setState(() {
      rooms.add({'roomName': roomController.text, 'storages': []});
    });
    roomController.clear();
  }

  void saveRoomsToFirestore() async {
    final User? user = FirebaseAuth.instance.currentUser;
    final userId = user!.uid; // Replace with logged-in user ID
    for (var room in rooms) {
      final roomDoc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('rooms')
          .add({'roomName': room['roomName'], 'createdAt': Timestamp.now()});

      await roomDoc.collection('storages').add({'storageName': 'Storage 1'});
    }
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Setup Rooms')),
      body: Column(
        children: [
          TextField(
            controller: roomController,
            decoration: InputDecoration(labelText: 'Room Name'),
          ),
          ElevatedButton(
            onPressed: addRoom,
            child: Text('Add Room'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: rooms.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(rooms[index]['roomName']),
                );
              },
            ),
          ),
          ElevatedButton(
            onPressed: saveRoomsToFirestore,
            child: Text('Save and Continue'),
          ),
        ],
      ),
    );
  }
}
