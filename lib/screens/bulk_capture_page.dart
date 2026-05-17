import 'dart:io';

import 'package:cinduhrella/screens/review_detected_items_page.dart';
import 'package:cinduhrella/services/alert_service.dart';
import 'package:cinduhrella/services/auth_service.dart';
import 'package:cinduhrella/services/media_service.dart';
import 'package:cinduhrella/services/wardrobe_capture_service.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

class BulkCapturePage extends StatefulWidget {
  const BulkCapturePage({super.key});

  @override
  State<BulkCapturePage> createState() => _BulkCapturePageState();
}

class _BulkCapturePageState extends State<BulkCapturePage> {
  final GetIt _getIt = GetIt.instance;
  late final MediaService _mediaService;
  late final WardrobeCaptureService _captureService;
  late final AuthService _authService;
  late final AlertService _alertService;

  List<File> _selectedImages = const [];
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _mediaService = _getIt.get<MediaService>();
    _captureService = _getIt.get<WardrobeCaptureService>();
    _authService = _getIt.get<AuthService>();
    _alertService = _getIt.get<AlertService>();
  }

  Future<void> _pickImages() async {
    final images = await _mediaService.getImagesFromGallery();
    if (!mounted) {
      return;
    }
    setState(() {
      _selectedImages = images;
    });
  }

  Future<void> _startCapture() async {
    final userId = _authService.user?.uid;
    if (userId == null || _selectedImages.isEmpty) {
      return;
    }

    setState(() {
      _processing = true;
    });

    final result = await _captureService.captureBatch(
      userId: userId,
      images: _selectedImages,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _processing = false;
    });

    _alertService.showToast(
      text: 'Detected ${result.drafts.length} draft item(s).',
      icon: Icons.check_circle,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReviewDetectedItemsPage(
          sessionId: result.session.sessionId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bulk Capture'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Upload a quick batch of wardrobe photos. The app will create draft items and only ask you to confirm what matters.',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Fast-start rules',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                      '1. Pick 3 to 10 item-focused photos or screenshots.'),
                  const Text('2. The app creates draft items automatically.'),
                  const Text('3. Confirm only the useful ones.'),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _processing ? null : _pickImages,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: Text(
                      _selectedImages.isEmpty
                          ? 'Choose Photos'
                          : 'Selected ${_selectedImages.length} photo(s)',
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_selectedImages.isNotEmpty) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 110,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _selectedImages.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _selectedImages[index],
                      width: 110,
                      height: 110,
                      fit: BoxFit.cover,
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: FilledButton(
          onPressed:
              _processing || _selectedImages.isEmpty ? null : _startCapture,
          child: Text(_processing ? 'Processing...' : 'Create Draft Closet'),
        ),
      ),
    );
  }
}
