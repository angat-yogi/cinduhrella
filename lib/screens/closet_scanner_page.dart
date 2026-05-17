import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:cinduhrella/models/closet_scan_detection.dart';
import 'package:cinduhrella/services/alert_service.dart';
import 'package:cinduhrella/services/auth_service.dart';
import 'package:cinduhrella/services/closet_scanner_service.dart';
import 'package:cinduhrella/services/media_service.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';

class ClosetScannerPage extends StatefulWidget {
  const ClosetScannerPage({super.key});

  @override
  State<ClosetScannerPage> createState() => _ClosetScannerPageState();
}

class _ClosetScannerPageState extends State<ClosetScannerPage> {
  static const int _minStableHits = 2;
  static const Duration _staleCandidateWindow = Duration(seconds: 8);
  static const Duration _stalePendingWindow = Duration(seconds: 12);

  final GetIt _getIt = GetIt.instance;
  late final ClosetScannerService _closetScannerService;
  late final AuthService _authService;
  late final AlertService _alertService;
  late final MediaService _mediaService;

  CameraController? _cameraController;
  Timer? _scanTimer;
  bool _cameraReady = false;
  bool _cameraSupported = true;
  bool _captureInFlight = false;
  bool _scanEnabled = true;
  bool _saving = false;
  String? _statusText;
  List<ClosetScanDetection> _latestFrameDetections = const [];
  List<ClosetScanDetection> _pendingDetections = const [];
  final Map<String, int> _candidateHitCounts = {};
  final Map<String, DateTime> _lastSeenAt = {};

  @override
  void initState() {
    super.initState();
    _closetScannerService = _getIt.get<ClosetScannerService>();
    _authService = _getIt.get<AuthService>();
    _alertService = _getIt.get<AlertService>();
    _mediaService = _getIt.get<MediaService>();
    _initializeCamera();
  }

  @override
  void dispose() {
    _scanTimer?.cancel();
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) {
          setState(() {
            _cameraSupported = false;
            _statusText =
                'No camera is available in this simulator. Use "Scan From Photo" to test detections.';
          });
        }
        return;
      }

      final camera = cameras.firstWhere(
        (item) => item.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }

      _cameraController = controller;
      if (mounted) {
        setState(() {
          _cameraReady = true;
          _statusText = 'Scanning closet every 1.5 seconds';
        });
      }
      _startScanLoop();
    } on CameraException catch (e) {
      if (mounted) {
        setState(() {
          _cameraSupported = false;
          _statusText =
              'Camera unavailable in this simulator (${e.code}). Use "Scan From Photo" to test detections.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cameraSupported = false;
          _statusText =
              'Could not start the camera here. Use "Scan From Photo" to test detections.';
        });
      }
    }
  }

  Future<void> _scanFromGallery() async {
    final file = await _mediaService.getImageFromGallery();
    if (file == null) {
      return;
    }
    setState(() {
      _statusText = 'Running scanner on selected photo...';
    });
    await _scanImageFile(file);
  }

  void _startScanLoop() {
    _scanTimer?.cancel();
    _scanTimer = Timer.periodic(const Duration(milliseconds: 1500), (_) async {
      if (!_scanEnabled || _captureInFlight || !mounted) {
        return;
      }
      await _scanFrame();
    });
  }

  Future<void> _scanFrame() async {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    _captureInFlight = true;
    try {
      final captured = await controller.takePicture();
      await _scanImageFile(File(captured.path));
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusText = 'Scanner error: $e';
        });
      }
    } finally {
      _captureInFlight = false;
    }
  }

  Future<void> _scanImageFile(File file) async {
    final detections = await _closetScannerService.detectClothes(file);
    if (!mounted) {
      return;
    }

    final stableDetections = _stableDetectionsFrom(detections);
    setState(() {
      _pendingDetections =
          _mergeDetections(_pendingDetections, stableDetections);
      _latestFrameDetections = stableDetections;
      _statusText = detections.isEmpty
          ? 'No clothing detected in the last scan.'
          : stableDetections.isEmpty
              ? 'Seen ${detections.length} candidate item(s). Hold steady to confirm.'
              : 'Confirmed ${stableDetections.length} stable item(s) in the last scan.';
    });
  }

  List<ClosetScanDetection> _stableDetectionsFrom(
    List<ClosetScanDetection> detections,
  ) {
    final now = DateTime.now();
    final stable = <ClosetScanDetection>[];
    final seenThisFrame = <String>{};

    for (final detection in detections) {
      final signature = _detectionSignature(detection);
      seenThisFrame.add(signature);
      _lastSeenAt[signature] = now;
      _candidateHitCounts[signature] =
          (_candidateHitCounts[signature] ?? 0) + 1;
      if ((_candidateHitCounts[signature] ?? 0) >= _minStableHits) {
        stable.add(detection);
      }
    }

    final expired = _lastSeenAt.entries
        .where((entry) => now.difference(entry.value) > _staleCandidateWindow)
        .map((entry) => entry.key)
        .toList(growable: false);
    for (final key in expired) {
      _lastSeenAt.remove(key);
      _candidateHitCounts.remove(key);
    }

    if (seenThisFrame.isEmpty) {
      _pendingDetections = _pendingDetections.where((item) {
        final lastSeen = _lastSeenAt[_detectionSignature(item)];
        return lastSeen != null &&
            now.difference(lastSeen) <= _stalePendingWindow;
      }).toList(growable: false);
    }

    return stable;
  }

  List<ClosetScanDetection> _mergeDetections(
    List<ClosetScanDetection> current,
    List<ClosetScanDetection> incoming,
  ) {
    final now = DateTime.now();
    final merged = current.where((existing) {
      final lastSeen = _lastSeenAt[_detectionSignature(existing)];
      return lastSeen != null &&
          now.difference(lastSeen) <= _stalePendingWindow;
    }).toList(growable: true);
    for (final detection in incoming) {
      final duplicateIndex = merged.indexWhere((existing) {
        final sameKey =
            _detectionSignature(existing) == _detectionSignature(detection);
        final confidenceGap =
            (existing.confidence - detection.confidence).abs() < 0.12;
        return sameKey && confidenceGap;
      });
      if (duplicateIndex == -1) {
        merged.add(detection);
      } else if (detection.confidence > merged[duplicateIndex].confidence) {
        merged[duplicateIndex] = detection.copyWith(
          approved: merged[duplicateIndex].approved,
        );
      }
    }
    return merged;
  }

  String _detectionSignature(ClosetScanDetection detection) {
    final x1 = (detection.bbox['x1'] as num?)?.toDouble() ?? 0;
    final y1 = (detection.bbox['y1'] as num?)?.toDouble() ?? 0;
    final x2 = (detection.bbox['x2'] as num?)?.toDouble() ?? 0;
    final y2 = (detection.bbox['y2'] as num?)?.toDouble() ?? 0;
    final centerXBucket = (((x1 + x2) / 2) / 120).floor();
    final centerYBucket = (((y1 + y2) / 2) / 120).floor();
    final areaBucket = (((x2 - x1) * (y2 - y1)) / 12000).round();
    return '${detection.duplicateKey}|$centerXBucket|$centerYBucket|$areaBucket';
  }

  Future<void> _saveApproved() async {
    final userId = _authService.user?.uid;
    if (userId == null) {
      return;
    }

    final approved = _pendingDetections
        .where((item) => item.approved)
        .toList(growable: false);
    if (approved.isEmpty) {
      _alertService.showToast(
        text: 'No approved closet items to save.',
        icon: Icons.error,
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    await _closetScannerService.saveApprovedItems(
      userId: userId,
      detections: approved,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _saving = false;
      _pendingDetections = _pendingDetections
          .where((item) => !item.approved)
          .toList(growable: false);
      _statusText = 'Saved ${approved.length} closet item(s) to Firebase.';
    });
    _alertService.showToast(
      text: 'Saved ${approved.length} closet item(s).',
      icon: Icons.check_circle,
    );
  }

  void _toggleApproved(ClosetScanDetection detection, bool selected) {
    setState(() {
      _pendingDetections = _pendingDetections
          .map(
            (item) => item.tempId == detection.tempId
                ? item.copyWith(approved: selected)
                : item,
          )
          .toList(growable: false);
    });
  }

  void _removeDetection(ClosetScanDetection detection) {
    setState(() {
      _pendingDetections = _pendingDetections
          .where((item) => item.tempId != detection.tempId)
          .toList(growable: false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Closet Scanner'),
        actions: [
          IconButton(
            onPressed: _captureInFlight ? null : _scanFromGallery,
            icon: const Icon(Icons.photo_library_outlined),
          ),
          IconButton(
            onPressed: !_cameraReady
                ? null
                : () {
                    setState(() {
                      _scanEnabled = !_scanEnabled;
                      _statusText = _scanEnabled
                          ? 'Scanning resumed.'
                          : 'Scanning paused.';
                    });
                  },
            icon: Icon(_scanEnabled ? Icons.pause : Icons.play_arrow),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _pendingDetections = const [];
                _latestFrameDetections = const [];
                _statusText = 'Temporary scan list cleared.';
              });
            },
            icon: const Icon(Icons.clear_all),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: _cameraReady && _cameraController != null
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      CameraPreview(_cameraController!),
                      Positioned(
                        top: 16,
                        left: 16,
                        right: 16,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _latestFrameDetections
                              .map(
                                (item) => Chip(
                                  backgroundColor:
                                      Colors.black.withValues(alpha: 0.65),
                                  label: Text(
                                    item.displayLabel,
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 16,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.65),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _statusText ?? 'Initializing scanner...',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  )
                : _cameraSupported
                    ? const Center(child: CircularProgressIndicator())
                    : Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.no_photography_outlined,
                                  size: 64),
                              const SizedBox(height: 16),
                              Text(
                                _statusText ??
                                    'Camera not available on this simulator.',
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              FilledButton.icon(
                                onPressed: _scanFromGallery,
                                icon: const Icon(Icons.photo_library_outlined),
                                label: const Text('Scan From Photo'),
                              ),
                            ],
                          ),
                        ),
                      ),
          ),
          Expanded(
            flex: 4,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Review detections',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text('${_pendingDetections.length} found'),
                    ],
                  ),
                ),
                Expanded(
                  child: _pendingDetections.isEmpty
                      ? const Center(
                          child: Text(
                            'Point the camera at your closet. Detected items will appear here.',
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _pendingDetections.length,
                          itemBuilder: (context, index) {
                            final detection = _pendingDetections[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.memory(
                                        detection.cropBytes,
                                        width: 88,
                                        height: 88,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            detection.displayLabel,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Category: ${detection.normalizedCategory}',
                                          ),
                                          Text(
                                            'Confidence: ${(detection.confidence * 100).round()}%',
                                          ),
                                          Text(
                                            'Colors: ${detection.colors.join(', ')}',
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      children: [
                                        Checkbox(
                                          value: detection.approved,
                                          onChanged: (value) {
                                            _toggleApproved(
                                              detection,
                                              value ?? false,
                                            );
                                          },
                                        ),
                                        IconButton(
                                          onPressed: () =>
                                              _removeDetection(detection),
                                          icon:
                                              const Icon(Icons.delete_outline),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: FilledButton(
          onPressed: _saving ? null : _saveApproved,
          child: Text(_saving ? 'Saving...' : 'Save Approved Items'),
        ),
      ),
    );
  }
}
