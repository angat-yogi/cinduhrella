import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:cinduhrella/services/alert_service.dart';
import 'package:cinduhrella/services/auth_service.dart';
import 'package:cinduhrella/services/media_service.dart';
import 'package:cinduhrella/services/navigation_service.dart';
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

  bool isLoading = false;

  String? _brand;
  String? _size;
  String? _color;
  String? _description;
  String? _imagePath;
  String? _selectedType;

  final List<String> _clothingTypes = ['Top', 'Bottom', 'Accessories'];
  final List<String> _brands = [
    'Zara',
    'Adidas',
    'Nike',
    'H&M',
    'Puma',
    'Levi\'s',
    'Uniqlo',
    'Forever 21',
    'Calvin Klein',
    'The North Face',
    'Other'
  ]; 
  final List<String> _sizes = ['Extra Small (XS)','Small (S)', 'Medium (M)', 'Large (L)', 'Extra Large (XXL)'];
  final List<String> _colors = ['Red', 'Blue', 'Green','Purple','Grey','White','Black','Other'];

  @override
  void initState() {
    super.initState();
    _authService = _getIt.get<AuthService>();
    _navigationService = _getIt.get<NavigationService>();
    _alertService = _getIt.get<AlertService>();
    _mediaService = _getIt.get<MediaService>();
    _storageService = _getIt.get<StorageService>();
    _databaseService = _getIt.get<DatabaseService>();
  }

  Future<void> _selectImage() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () async {
                  Navigator.pop(context); // Close the dialog
                  final pickedFile = await _picker.pickImage(
                    source: ImageSource.camera,
                    imageQuality: 80,
                  );
                  if (pickedFile != null) {
                    setState(() {
                      _imagePath = pickedFile.path;
                    });
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () async {
                  Navigator.pop(context); // Close the dialog
                  final pickedFile = await _picker.pickImage(
                    source: ImageSource.gallery,
                    imageQuality: 80,
                  );
                  if (pickedFile != null) {
                    setState(() {
                      _imagePath = pickedFile.path;
                    });
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _addCloth() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      if (_imagePath == null) {
        _alertService.showToast(text: "Please select image",icon: Icons.image);
      }

      if (_imagePath != null) {
        setState(() {
          isLoading=true;
        });
        String? downloadUrl = await _storageService.uploadClothImage(
          file: File(_imagePath!),
          uid: _authService.user!.uid,
          clothType: _selectedType!,
        );
        setState(() {
          isLoading = false; // Stop loading
        });
        if (downloadUrl != null) {
          String clothId = '${_authService.user!.uid}_${_selectedType}_${DateTime.now().millisecondsSinceEpoch}';
          Cloth newCloth = Cloth(
            clothId: clothId,
            uid: _authService.user!.uid,
            imageUrl: downloadUrl,
            brand: _brand,
            size: _size,
            color: _color,
            description: _description,
            type: _selectedType,
          );

          await _databaseService.addClothForUser(_authService.user!.uid, newCloth);
          Navigator.pop(context);
        } else {
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
        child: SingleChildScrollView( // Wrap with SingleChildScrollView
          child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton(
                      onPressed: _selectImage,
                      child: const Text('Select Image'),
                    ),
                    const SizedBox(height: 16.0), // Added spacing

                    if (_imagePath != null)
                      Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16.0), // Adjust the radius as needed
                            child: Image.file(
                              File(_imagePath!),
                              height: 150,
                              width: 150,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 16.0), // Added spacing
                        ],
                      ),

                    
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Brand',
                        contentPadding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
                      ),
                      value: _brand,
                      items: _brands.map((String brand) {
                        return DropdownMenuItem<String>(
                          value: brand,
                          child: Text(brand),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _brand = newValue;
                        });
                      },
                      validator: (value) => value == null ? 'Please select a brand' : null,
                    ),
                    const SizedBox(height: 16.0), // Added spacing
                    
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Size',
                        contentPadding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
                      ),
                      value: _size,
                      items: _sizes.map((String size) {
                        return DropdownMenuItem<String>(
                          value: size,
                          child: Text(size),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _size = newValue;
                        });
                      },
                      validator: (value) => value == null ? 'Please select a size' : null,
                    ),
                    const SizedBox(height: 16.0), // Added spacing

                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Color',
                        contentPadding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
                      ),
                      value: _color,
                      items: _colors.map((String color) {
                        return DropdownMenuItem<String>(
                          value: color,
                          child: Text(color),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _color = newValue;
                        });
                      },
                      validator: (value) => value == null ? 'Please select a color' : null,
                    ),
                    const SizedBox(height: 16.0), // Added spacing

                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Type',
                        contentPadding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
                      ),
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
                    const SizedBox(height: 16.0), // Added spacing

                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(vertical: 2.0, horizontal: 12.0),
                      ),
                      maxLength: 200,
                      onSaved: (value) => _description = value,
                      validator: (value) => value == null || value.isEmpty ? 'Please enter a description' : null,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (value) { // Handle the action when "Done" is pressed
                      FocusScope.of(context).unfocus(); // This dismisses the keyboard
                    },
                    ),
                    const SizedBox(height: 4.0), // Added spacing

                    ElevatedButton(
                      onPressed: _addCloth,
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ),
        ),
      ),
    );
  }
}
