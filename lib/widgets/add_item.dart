import 'package:cinduhrella/services/alert_service.dart';
import 'package:cinduhrella/services/auth_service.dart';
import 'package:cinduhrella/services/media_service.dart';
import 'package:cinduhrella/services/navigation_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cinduhrella/services/storage_service.dart';
import 'package:cinduhrella/services/database_service.dart';
import 'package:cinduhrella/models/cloth.dart';
import 'package:get_it/get_it.dart';

class AddItemForm extends StatefulWidget {
  const AddItemForm({Key? key}) : super(key: key);

  @override
  _AddItemFormState createState() => _AddItemFormState();
}

class _AddItemFormState extends State<AddItemForm> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
   final GetIt _getIt = GetIt.instance;
  late AuthService _authService;
  late NavigationService _navigationService;
  late AlertService _alertService;
  late MediaService _mediaService;
  late StorageService _storageService;
  late DatabaseService _databaseService;
  bool isLoading=false;

  String? email, password, username,fullname, confirmPassword;
  File? _profileImage;

  @override
  void initState() {
    super.initState();
    _authService = _getIt.get<AuthService>();
    _navigationService = _getIt.get<NavigationService>();
    _alertService = _getIt.get<AlertService>();
    _mediaService = _getIt.get<MediaService>();
    _storageService=_getIt.get<StorageService>();
    _databaseService=_getIt.get<DatabaseService>();
  }

  String? _brand;
  String? _size;
  String? _color;
  String? _description;
  String? _imagePath;
  String? _selectedType;

  final List<String> _clothingTypes = ['Top', 'Bottom', 'Accessories'];

  Future<void> _selectImage() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      setState(() {
        _imagePath = pickedFile.path;
      });
    }
  }

  Future<void> _addCloth() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Upload the image and get the download URL
      if (_imagePath != null) {
        String? downloadUrl = await _storageService.uploadClothImage(
          file: File(_imagePath!),
          uid: _authService.user!.uid, // Replace with the actual user UID
          clothType: _selectedType!,
        );

        if (downloadUrl != null) {
          // Create a Cloth object and save to Firestore
           String clothId = '${_authService.user!.uid}_${_selectedType}_${DateTime.now().millisecondsSinceEpoch}';
          Cloth newCloth = Cloth(
          clothId: clothId, // You can generate an ID or leave it empty for Firestore to create
          uid: _authService.user!.uid,
          imageUrl: downloadUrl,
          brand: _brand,
          size: _size,
          description: _description,
          type: _selectedType,
        );

        await _databaseService.addClothForUser(newCloth.uid!, newCloth);
          Navigator.pop(context); // Go back after saving
        } else {
          // Handle error: image upload failed
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Image upload failed')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Cloth'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Brand'),
                onSaved: (value) => _brand = value,
                validator: (value) => value!.isEmpty ? 'Please enter a brand' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Size'),
                onSaved: (value) => _size = value,
                validator: (value) => value!.isEmpty ? 'Please enter a size' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Color'),
                onSaved: (value) => _color = value,
                validator: (value) => value!.isEmpty ? 'Please enter a color' : null,
              ),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Type'),
                value: _selectedType,
                items: _clothingTypes.map((String type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedType = newValue;
                  });
                },
                validator: (value) => value == null ? 'Please select a type' : null,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Description'),
                onSaved: (value) => _description = value,
                validator: (value) => value!.isEmpty ? 'Please enter a description' : null,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _selectImage,
                child: const Text('Select Image'),
              ),
              const SizedBox(height: 16),
              if (_imagePath != null)
                Image.file(
                  File(_imagePath!),
                  height: 100,
                  width: 100,
                  fit: BoxFit.cover,
                ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _addCloth,
                child: const Text('Add Cloth'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
