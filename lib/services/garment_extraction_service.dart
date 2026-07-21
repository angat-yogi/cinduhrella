import 'dart:convert';
import 'dart:io';

import 'package:cinduhrella/models/extracted_garment.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

class GarmentExtractionService {
  String get _baseUrl {
    final configured = dotenv.env['CLOSET_SCANNER_BACKEND_URL'] ?? '';
    if (configured.isNotEmpty) {
      return configured;
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://127.0.0.1:8000';
  }

  Future<List<ExtractedGarment>> extractGarments(File imageFile) async {
    final uri = Uri.parse('$_baseUrl/extract-garments');
    final request = http.MultipartRequest('POST', uri)
      ..files.add(
        await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
          filename: path.basename(imageFile.path),
        ),
      );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        'Garment extraction request failed: ${response.statusCode} ${response.body}',
      );
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final garments = List<Map<String, dynamic>>.from(
      payload['garments'] ?? const [],
    );

    return garments.map(ExtractedGarment.fromJson).toList();
  }
}
