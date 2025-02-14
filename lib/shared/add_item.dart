import 'package:cinduhrella/models/cloth.dart';
import 'package:cinduhrella/services/auth_service.dart';
import 'package:cinduhrella/services/chat_service.dart';
import 'package:cinduhrella/services/database_service.dart';
import 'package:cinduhrella/shared/image_picker_dialog.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

class AddItemDialog extends StatefulWidget {
  final String? roomId;
  final String? storageId;

  const AddItemDialog({super.key, this.roomId, this.storageId});

  @override
  State<AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<AddItemDialog> {
  final DatabaseService _databaseService =
      GetIt.instance.get<DatabaseService>();
  final AuthService _authService = GetIt.instance.get<AuthService>();
  final ChatService _chatService = GetIt.instance.get<ChatService>();

  final TextEditingController descriptionController = TextEditingController();
  String? selectedSize;
  String? selectedType;
  String? selectedColor;
  String? selectedBrand;
  String? imageUrl;
  bool isLoading = false;

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
            ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return ImagePickerDialog(
                      userId: _authService.user!.uid,
                      pathType:
                          widget.roomId != null ? 'storage' : 'unassigned',
                      roomId: widget.roomId,
                      storageId: widget.storageId,
                      onImagePicked: (String uploadedImageUrl) {
                        setState(() {
                          imageUrl = uploadedImageUrl;
                          isLoading = true;
                        });

                        // 🔹 Get AI Analysis and Auto-fill Form
                        _chatService
                            .getClothingDetailsFromChatGPT(uploadedImageUrl)
                            .then((details) {
                          setState(() {
                            selectedType = details["type"];
                            selectedBrand = details["brand"];
                            selectedColor = details["color"];
                            selectedSize = details["size"];
                            descriptionController.text =
                                details["description"] ??
                                    ""; // ✅ AI-generated description
                            isLoading = false;
                          });
                        });
                      },
                    );
                  },
                );
              },
              child: const Text('Pick Image First'),
            ),
            const SizedBox(height: 10),
            if (imageUrl != null)
              Image.network(imageUrl!,
                  width: 180, height: 180, fit: BoxFit.cover),
            if (isLoading) const CircularProgressIndicator(),
            const SizedBox(height: 20),
            if (imageUrl != null && !isLoading) ...[
              DropdownButtonFormField<String>(
                value: selectedBrand,
                decoration: const InputDecoration(labelText: "Brand"),
                items: brands
                    .map((brand) =>
                        DropdownMenuItem(value: brand, child: Text(brand)))
                    .toList(),
                onChanged: (newValue) =>
                    setState(() => selectedBrand = newValue),
              ),
              DropdownButtonFormField<String>(
                value: selectedSize,
                decoration: const InputDecoration(labelText: "Size"),
                items: sizes
                    .map((size) =>
                        DropdownMenuItem(value: size, child: Text(size)))
                    .toList(),
                onChanged: (newValue) =>
                    setState(() => selectedSize = newValue),
              ),
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: const InputDecoration(labelText: "Type"),
                items: types
                    .map((type) =>
                        DropdownMenuItem(value: type, child: Text(type)))
                    .toList(),
                onChanged: (newValue) =>
                    setState(() => selectedType = newValue),
              ),
              DropdownButtonFormField<String>(
                value: selectedColor,
                decoration: const InputDecoration(labelText: "Color"),
                items: colors
                    .map((color) =>
                        DropdownMenuItem(value: color, child: Text(color)))
                    .toList(),
                onChanged: (newValue) =>
                    setState(() => selectedColor = newValue),
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
            child: const Text('Cancel')),
        TextButton(
          onPressed: () async {
            if (imageUrl != null) {
              Cloth newCloth = Cloth(
                clothId: FirebaseFirestore.instance
                    .collection('users/${_authService.user!.uid}/items')
                    .doc()
                    .id,
                brand: selectedBrand,
                size: selectedSize,
                type: selectedType,
                color: selectedColor,
                description: descriptionController.text.trim(),
                imageUrl: imageUrl!,
                storageId: widget.storageId,
                uid: _authService.user!.uid,
              );

              if (widget.roomId != null && widget.storageId != null) {
                // ✅ Save inside a specific storage
                await _databaseService.addCloth(_authService.user!.uid,
                    widget.roomId!, widget.storageId!, newCloth);
              } else {
                // ✅ Save as an unassigned item
                await _databaseService.addUnassignedCloth(
                    _authService.user!.uid, newCloth);
              }

              Navigator.of(context).pop();
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
