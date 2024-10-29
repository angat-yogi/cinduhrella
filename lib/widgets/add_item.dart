import 'package:flutter/material.dart';

class AddItemForm extends StatefulWidget {
  const AddItemForm({Key? key}) : super(key: key);

  @override
  _AddItemFormState createState() => _AddItemFormState();
}

class _AddItemFormState extends State<AddItemForm> {
  final _formKey = GlobalKey<FormState>();

  String? _brand;
  String? _size;
  String? _color;
  String? _description;
  String? _imagePath;

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
              TextFormField(
                decoration: const InputDecoration(labelText: 'Description'),
                onSaved: (value) => _description = value,
                validator: (value) => value!.isEmpty ? 'Please enter a description' : null,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    // Save item here or pass it back to ClosetPage
                    Navigator.pop(context);
                  }
                },
                child: const Text('Add Cloth'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
