import 'package:cinduhrella/models/cloth.dart';
import 'package:cinduhrella/services/auth_service.dart';
import 'package:cinduhrella/services/database_service.dart';
import 'package:cinduhrella/shared/image_picker_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

class AddItemDialog extends StatefulWidget {
  const AddItemDialog({super.key});

  @override
  State<AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<AddItemDialog> {
  final DatabaseService _databaseService =
      GetIt.instance.get<DatabaseService>();
  final AuthService _authService = GetIt.instance.get<AuthService>();

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
  ];
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

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New Item'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image Picker Button
            ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return ImagePickerDialog(
                      userId: _authService.user!.uid,
                      pathType: 'unassigned',
                      onImagePicked: (String uploadedImageUrl) {
                        setState(() {
                          imageUrl = uploadedImageUrl;
                        });
                      },
                    );
                  },
                );
              },
              child: const Text('Pick Image First'),
            ),

            const SizedBox(height: 10),

            // Show selected image immediately
            if (imageUrl != null)
              Image.network(imageUrl!,
                  width: 180, height: 180, fit: BoxFit.cover),

            const SizedBox(height: 20),

            // Only show the form fields if an image has been selected
            if (imageUrl != null) ...[
              DropdownButtonFormField<String>(
                value: selectedBrand,
                decoration: const InputDecoration(labelText: "Brand"),
                items: brands.map((size) {
                  return DropdownMenuItem(value: size, child: Text(size));
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    selectedBrand = newValue!;
                  });
                },
              ),
              DropdownButtonFormField<String>(
                value: selectedSize,
                decoration: const InputDecoration(labelText: "Size"),
                items: sizes.map((size) {
                  return DropdownMenuItem(value: size, child: Text(size));
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    selectedSize = newValue!;
                  });
                },
              ),
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: const InputDecoration(labelText: "Type"),
                items: types.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    selectedType = newValue!;
                  });
                },
              ),
              DropdownButtonFormField<String>(
                value: selectedColor,
                decoration: const InputDecoration(labelText: "Color"),
                items: colors.map((color) {
                  return DropdownMenuItem(value: color, child: Text(color));
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    selectedColor = newValue!;
                  });
                },
              ),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
            ]
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            if (selectedBrand == null ||
                selectedSize == null ||
                selectedType == null ||
                selectedColor == null ||
                imageUrl == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('All fields and an image are required!'),
                    backgroundColor: Colors.red),
              );
              return;
            }
            DocumentReference newItemRef = FirebaseFirestore.instance
                .collection('users/${_authService.user!.uid}/unassigned')
                .doc(); // Generate ID for the item
            Cloth newCloth = Cloth(
              clothId: newItemRef.id, // Assign the generated ID
              brand: selectedBrand!,
              size: selectedSize!,
              type: selectedType!,
              color: selectedColor!,
              description: descriptionController.text.trim(),
              imageUrl: imageUrl!,
              storageId: null, // Unassigned item, so no storage ID
              uid: _authService.user!.uid,
            );

            // ✅ Use `DatabaseService` to add the item properly
            await _databaseService.addUnassignedCloth(
                _authService.user!.uid, newCloth);

            Navigator.of(context).pop();
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
