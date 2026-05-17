import 'dart:convert';

import 'package:cinduhrella/models/try_on.dart';
import 'package:cinduhrella/services/mock_try_on_renderer.dart';
import 'package:cinduhrella/services/try_on_renderer.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class RemoteTryOnRenderer implements TryOnRenderer {
  RemoteTryOnRenderer({
    MockTryOnRenderer? fallbackRenderer,
  }) : _fallbackRenderer = fallbackRenderer ?? MockTryOnRenderer();

  final MockTryOnRenderer _fallbackRenderer;

  @override
  Future<TryOnPreview> render(TryOnRequest request) async {
    final endpoint = dotenv.env['TRY_ON_RENDERER_URL'] ?? '';
    if (endpoint.isEmpty) {
      return _fallbackRenderer.render(request);
    }

    try {
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(request.toJson()),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return TryOnPreview.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      }
    } catch (_) {
      // Fall through to the local placeholder renderer while the backend is unavailable.
    }

    return _fallbackRenderer.render(request);
  }
}
