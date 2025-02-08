import 'dart:io';
import 'package:cinduhrella/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImagePickerDialog extends StatelessWidget {
  final Function(String) onImagePicked;
  final String userId; // Pass userId to store images correctly
  final String pathType; // Determines if the image is for "room" or "storage"
  final String? roomId; // Only needed if uploading storage images
  final String? storageId;

  const ImagePickerDialog({
    super.key,
    required this.onImagePicked,
    required this.userId,
    required this.pathType,
    this.roomId,
    this.storageId,
  });

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);

    if (image != null) {
      final File imageFile = File(image.path);
      final StorageService storageService = StorageService();

      // ✅ Store context for dialog reference
      late BuildContext dialogContext;

      // ✅ Show loading indicator while uploading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          dialogContext = ctx; // Assign the dialog's context
          return const Center(child: CircularProgressIndicator());
        },
      );

      // ✅ Upload image to Firebase Storage
      String? imageUrl = await storageService.uploadImage(
        file: imageFile,
        uid: userId,
        pathType: pathType,
        roomId: roomId,
        storageId: storageId,
      );

      // ✅ Close the loading indicator only if widget is still mounted
      if (dialogContext.mounted) {
        Navigator.of(dialogContext).pop();
      }

      // ✅ Return Firebase Storage URL if successful
      if (imageUrl != null) {
        onImagePicked(imageUrl);
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image upload failed!'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    // ✅ Ensure dialog is closed safely
    if (context.mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Select Image",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () => _pickImage(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo),
              title: const Text('Choose from Gallery'),
              onTap: () => _pickImage(context, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}
