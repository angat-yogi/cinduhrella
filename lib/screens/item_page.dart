import 'package:cinduhrella/screens/storage_page.dart';
import 'package:cinduhrella/services/alert_service.dart';
import 'package:cinduhrella/services/database_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

class ItemPage extends StatefulWidget {
  final String itemId;
  final String? roomId;
  final String? storageId;
  final Map<String, dynamic>? initialItemData;

  const ItemPage({
    super.key,
    required this.itemId,
    required this.roomId,
    required this.storageId,
    this.initialItemData,
  });

  @override
  ItemPageState createState() => ItemPageState();
}

class ItemPageState extends State<ItemPage> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final String userId = FirebaseAuth.instance.currentUser!.uid;
  final GetIt _getIt = GetIt.instance;
  late DatabaseService _databaseService;
  late AlertService _alertService;

  bool isEditing = false;
  bool _isLoading = true;
  Map<String, dynamic>? itemData;
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

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
    _databaseService = _getIt.get<DatabaseService>();
    _alertService = _getIt.get<AlertService>();
    if (widget.initialItemData != null) {
      _applyItemData(widget.initialItemData!);
      _isLoading = false;
    }
    _loadItemData();
  }

  Future<void> _loadItemData() async {
    try {
      final itemSnapshot = await _itemDocumentRef().get();
      if (itemSnapshot.exists) {
        _applyItemData(itemSnapshot.data() as Map<String, dynamic>);
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _applyItemData(Map<String, dynamic> data) {
    setState(() {
      itemData = {
        ...?itemData,
        ...data,
      };
      selectedBrand = (itemData?['brand'] ?? brands.last).toString();
      descriptionController.text = (itemData?['description'] ?? '').toString();
      notesController.text = (itemData?['notes'] ?? '').toString();
      selectedSize = _normalizeChoice(
        value: itemData?['size'],
        allowedValues: sizes,
        fallback: sizes[0],
      );
      selectedType = _normalizeChoice(
        value: itemData?['type'],
        allowedValues: types,
        fallback: types[0],
      );
      selectedColor = (itemData?['color'] ?? 'Black').toString();
    });
  }

  String _normalizeChoice({
    required dynamic value,
    required List<String> allowedValues,
    required String fallback,
  }) {
    final normalized = (value ?? '').toString();
    return allowedValues.contains(normalized) ? normalized : fallback;
  }

  Future<void> _updateItem() async {
    final payload = {
      'brand': selectedBrand,
      'size': selectedSize,
      'type': selectedType,
      'color': selectedColor,
      'description': descriptionController.text.trim(),
      'notes': notesController.text.trim(),
    };

    await _itemDocumentRef().set(payload, SetOptions(merge: true));

    setState(() {
      isEditing = false;
      itemData = {
        ...?itemData,
        ...payload,
      };
    });

    _alertService.showToast(
        text: "Item updated successfully!", icon: Icons.check_box_rounded);

    if (mounted && widget.roomId != null && widget.storageId != null) {
      String? storageName = await _databaseService.getStorageName(
          userId, widget.roomId!, widget.storageId!);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => StoragePage(
            storageId: widget.storageId!,
            storageName: storageName ?? "Unknown Storage", // Fallback name
            roomId: widget.roomId!,
          ),
        ),
      );
    }
  }

  Future<void> _deleteItem() async {
    final shouldDelete = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete item?'),
            content: const Text(
              'This removes the closet item and its saved details. This cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;

    if (!shouldDelete) {
      return;
    }

    await _itemDocumentRef().delete();
    if (!mounted) {
      return;
    }

    _alertService.showToast(
      text: "Item deleted successfully!",
      icon: Icons.delete_outline_rounded,
    );
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (itemData == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Item')),
        body: const Center(
          child: Text('This item could not be loaded.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? "Edit Item" : _pageTitle(itemData!),
        ),
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
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _deleteItem,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
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
                          initialValue: selectedBrand,
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
                          initialValue: selectedSize,
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
                          initialValue: selectedType,
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
                          initialValue: selectedColor,
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
                        const SizedBox(height: 12),
                        TextField(
                          controller: notesController,
                          decoration: const InputDecoration(
                            labelText: 'Notes',
                            hintText:
                                'Fit notes, styling ideas, season, occasion, care instructions...',
                          ),
                          maxLines: 4,
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
                        if ((itemData?['notes'] ?? '')
                            .toString()
                            .trim()
                            .isNotEmpty)
                          Text(
                            "Notes: ${itemData?['notes']}",
                            style: const TextStyle(fontSize: 16),
                          ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }

  String _pageTitle(Map<String, dynamic> data) {
    final displayLabel = (data['displayLabel'] ?? '').toString().trim();
    if (displayLabel.isNotEmpty) {
      return displayLabel;
    }
    final description = (data['description'] ?? '').toString().trim();
    if (description.isNotEmpty) {
      return description;
    }
    final brand = (data['brand'] ?? '').toString().trim();
    if (brand.isNotEmpty) {
      return brand;
    }
    return 'Item Details';
  }

  DocumentReference<Map<String, dynamic>> _itemDocumentRef() {
    if (widget.roomId != null && widget.storageId != null) {
      return firestore
          .collection(
            'users/$userId/rooms/${widget.roomId}/storages/${widget.storageId}/items',
          )
          .doc(widget.itemId);
    }

    final closetRef =
        firestore.collection('users/$userId/closetItems').doc(widget.itemId);
    return closetRef;
  }
}
