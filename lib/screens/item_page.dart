import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ItemPage extends StatefulWidget {
  final String itemId;
  final String roomId;
  final String storageId;

  const ItemPage({
    super.key,
    required this.itemId,
    required this.roomId,
    required this.storageId,
  });

  @override
  ItemPageState createState() => ItemPageState();
}

class ItemPageState extends State<ItemPage> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final String userId = FirebaseAuth.instance.currentUser!.uid;

  bool isEditing = false;
  Map<String, dynamic>? itemData;
  final TextEditingController brandController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  String? selectedSize;
  String? selectedType;
  String? selectedColor;
  String? selectedBrand;

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
    "NorthFace",
    "Gucci",
    "H&M",
    "Louis Vuitton",
    "Prada",
    "Others"
  ]; // Add more as needed

  @override
  void initState() {
    super.initState();
    _loadItemData();
  }

  Future<void> _loadItemData() async {
    DocumentSnapshot itemSnapshot = await firestore
        .collection(
            'users/$userId/rooms/${widget.roomId}/storages/${widget.storageId}/items')
        .doc(widget.itemId)
        .get();

    if (itemSnapshot.exists) {
      setState(() {
        itemData = itemSnapshot.data() as Map<String, dynamic>;
        selectedBrand = itemData?['brand'] ?? brands[0];
        descriptionController.text = itemData?['description'] ?? '';
        selectedSize = itemData?['size'] ?? sizes[0]; // Default to first size
        selectedType = itemData?['type'] ?? types[0]; // Default to first type
        selectedColor = itemData?['color'] ?? 'Black'; // Default color
      });
    }
  }

  Future<void> _updateItem() async {
    await firestore
        .collection(
            'users/$userId/rooms/${widget.roomId}/storages/${widget.storageId}/items')
        .doc(widget.itemId)
        .update({
      'brand': selectedBrand,
      'size': selectedSize,
      'type': selectedType,
      'color': selectedColor,
      'description': descriptionController.text.trim(),
    });

    setState(() {
      isEditing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Item updated successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (itemData == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(
            isEditing ? "Edit Item" : itemData?['brand'] ?? "Item Details"),
        actions: [
          if (!isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  isEditing = true;
                });
              },
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Image.network(itemData?['imageUrl'] ?? '',
                height: 200, fit: BoxFit.cover),
            const SizedBox(height: 16),
            isEditing
                ? Column(
                    children: [
                      // Brand Autocomplete Dropdown
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
                        items: [
                          "Black",
                          "White",
                          "Blue",
                          "Red",
                          "Green",
                          "Yellow",
                          "Pink",
                          "Gray"
                        ].map((color) {
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
                      ElevatedButton(
                        onPressed: _updateItem,
                        child: const Text("Save Changes"),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Brand: ${itemData?['brand']}",
                          style: const TextStyle(fontSize: 16)),
                      Text("Type: ${itemData?['type']}",
                          style: const TextStyle(fontSize: 16)),
                      Text("Size: ${itemData?['size']}",
                          style: const TextStyle(fontSize: 16)),
                      Text("Color: ${itemData?['color']}",
                          style: const TextStyle(fontSize: 16)),
                      Text("Description: ${itemData?['description']}",
                          style: const TextStyle(fontSize: 16)),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}
