import 'package:cinduhrella/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';
import 'package:cinduhrella/services/database_service.dart';
import 'package:cinduhrella/services/alert_service.dart';

class UnassignedItemsSection extends StatelessWidget {
  final DatabaseService _databaseService =
      GetIt.instance.get<DatabaseService>();
  final AuthService _authService = GetIt.instance.get<AuthService>();
  final AlertService _alertService = GetIt.instance.get<AlertService>();
  final String userId = GetIt.instance.get<AuthService>().user!.uid;

  UnassignedItemsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Unassigned Items",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users/$userId/unassigned')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final items = snapshot.data?.docs ?? [];
            if (items.isEmpty) return const Text("No unassigned items found.");
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final itemData = item.data() as Map<String, dynamic>;
                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: itemData['imageUrl'] != null
                        ? Image.network(itemData['imageUrl'],
                            width: 50, height: 50)
                        : const Icon(Icons.image, size: 50),
                    title: Text(itemData['brand'] ?? "Unknown Item"),
                    subtitle: Text(itemData['type'] ?? "No Type"),
                    trailing: IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _assignItemDialog(
                          context, item.id, itemData), // ✅ Opens Assign Dialog
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  /// **📌 Assign Item to Room/Storage Dialog**
  void _assignItemDialog(
      BuildContext context, String itemId, Map<String, dynamic> itemData) {
    String? selectedRoom;
    String? selectedStorage;
    List<Map<String, dynamic>> rooms = [];
    List<Map<String, dynamic>> storages = [];
    bool isLoadingRooms = true;

    /// **📌 Fetch Storages when a Room is Selected**
    void fetchStorages(String roomId, Function(void Function()) updateDialog) {
      _databaseService
          .getStorages(_authService.user!.uid, roomId)
          .listen((storageList) {
        updateDialog(() {
          storages = storageList;
        });
      });
    }

    /// **📌 Shows the Dialog Only After Data is Ready**
    void _showDialog() {
      showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: const Text('Assign Item'),
                content: isLoadingRooms
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Room Dropdown
                          DropdownButtonFormField<String>(
                            value: selectedRoom,
                            decoration:
                                const InputDecoration(labelText: "Select Room"),
                            items: rooms.map((room) {
                              return DropdownMenuItem(
                                value: room['roomId']?.toString() ?? '',
                                child: Text(room['roomName']?.toString() ??
                                    'Unknown Room'),
                              );
                            }).toList(),
                            onChanged: (newValue) {
                              setState(() {
                                selectedRoom = newValue;
                                selectedStorage = null;
                                if (newValue != null) {
                                  fetchStorages(newValue, setState);
                                }
                              });
                            },
                          ),

                          // Storage Dropdown (optional)
                          DropdownButtonFormField<String>(
                            value: selectedStorage,
                            decoration: const InputDecoration(
                                labelText: "Select Storage (Optional)"),
                            items: storages.map((storage) {
                              return DropdownMenuItem(
                                value: storage['storageId']?.toString() ?? '',
                                child: Text(
                                    storage['storageName']?.toString() ??
                                        'Unknown Storage'),
                              );
                            }).toList(),
                            onChanged: (newValue) {
                              setState(() {
                                selectedStorage = newValue;
                              });
                            },
                          ),
                        ],
                      ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () async {
                      if (selectedRoom == null || selectedRoom!.isEmpty) {
                        _alertService.showToast(
                          text: "Please select at least a room!",
                          icon: Icons.error,
                        );
                        return;
                      }

                      await _databaseService.assignItemToRoomStorage(
                        _authService.user!.uid,
                        itemId,
                        selectedRoom!,
                        selectedStorage ?? '',
                        itemData,
                      );

                      Navigator.pop(context);
                    },
                    child: const Text('Assign'),
                  ),
                ],
              );
            },
          );
        },
      );
    }

    /// **📌 Fetch Rooms Before Opening the Dialog**
    void fetchRoomsAndShowDialog() {
      _databaseService.getRooms(_authService.user!.uid).listen((roomList) {
        rooms = roomList;
        isLoadingRooms = false;
        if (context.mounted) {
          _showDialog();
        }
      });
    }

    fetchRoomsAndShowDialog();
  }
}
