import 'package:cinduhrella/screens/item_page.dart';
import 'package:cinduhrella/shared/image_picker_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StoragePage extends StatelessWidget {
  final String storageId;
  final String storageName;
  final String roomId;

  const StoragePage({
    super.key,
    required this.storageId,
    required this.storageName,
    required this.roomId,
  });

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
              crossAxisCount: 3, // Three items per row
              crossAxisSpacing: 8.0,
              mainAxisSpacing: 8.0,
              childAspectRatio: 0.75, // Adjust aspect ratio to fit images
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
          _showAddItemDialog(context, firestore, userId, roomId, storageId);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddItemDialog(BuildContext context, FirebaseFirestore firestore,
      String userId, String roomId, String storageId) {
    final TextEditingController descriptionController = TextEditingController();
    String? selectedSize;
    String? selectedType;
    String? selectedColor;
    String? selectedBrand;
    String? imageUrl;

    final List<String> sizes = ["XS", "S", "M", "L", "XL"];
    final List<String> types = [
      "Top Wear",
      "Bottom Wear",
      "Accessories",
      "Others"
    ];
    final List<String> brands = [
      "Nike",
      "Adidas",
      "Zara",
      "Gucci",
      "H&M",
      "Louis Vuitton",
      "Prada",
      "Others"
    ]; // Add more as needed
    final List<String> colors = [
      "Black",
      "White",
      "Blue",
      "Red",
      "Green",
      "Yellow",
      "Pink",
      "Gray"
    ];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add New Item'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Brand
                    DropdownButtonFormField<String>(
                      value: selectedBrand,
                      decoration: const InputDecoration(labelText: "Brand"),
                      items: brands.map((size) {
                        return DropdownMenuItem(
                          value: size,
                          child: Text(size),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          selectedBrand = newValue!;
                        });
                      },
                    ),

                    // Size Dropdown
                    DropdownButtonFormField<String>(
                      value: selectedSize,
                      decoration: const InputDecoration(labelText: "Size"),
                      items: sizes.map((size) {
                        return DropdownMenuItem(
                          value: size,
                          child: Text(size),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          selectedSize = newValue!;
                        });
                      },
                    ),

                    // Type Dropdown
                    DropdownButtonFormField<String>(
                      value: selectedType,
                      decoration: const InputDecoration(labelText: "Type"),
                      items: types.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          selectedType = newValue!;
                        });
                      },
                    ),

                    // Color Dropdown
                    DropdownButtonFormField<String>(
                      value: selectedColor,
                      decoration: const InputDecoration(labelText: "Color"),
                      items: colors.map((color) {
                        return DropdownMenuItem(
                          value: color,
                          child: Text(color),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          selectedColor = newValue!;
                        });
                      },
                    ),

                    // Description
                    TextField(
                      controller: descriptionController,
                      decoration:
                          const InputDecoration(labelText: 'Description'),
                      maxLines: 3,
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

                    // Image Picker Button
                    ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return ImagePickerDialog(
                              userId: userId,
                              pathType: 'item',
                              roomId: roomId,
                              storageId: storageId,
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
                    final description = descriptionController.text.trim();

                    if (selectedBrand == null ||
                        selectedSize == null ||
                        selectedType == null ||
                        selectedColor == null ||
                        imageUrl == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('All fields and an image are required!'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    // Save item details to Firestore
                    await firestore
                        .collection(
                            'users/$userId/rooms/$roomId/storages/$storageId/items')
                        .add({
                      'brand': selectedBrand,
                      'size': selectedSize,
                      'type': selectedType,
                      'color': selectedColor,
                      'description': description,
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
