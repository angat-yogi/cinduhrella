import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class ChatService {
  final String _openAiApiKey = dotenv.env['OPENAI_API_KEY'] ?? '';
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
  final List<String> sizes = ["XS", "S", "M", "L", "XL"];
  ChatService();
  Future<String> convertImageToBase64(String imageUrl) async {
    try {
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        return base64Encode(bytes);
      } else {
        throw Exception("Failed to load image");
      }
    } catch (e) {
      print("Error converting image to Base64: $e");
      return "";
    }
  }

  /// **🔹 Analyze Clothing Image using GPT-4 Turbo Vision**
  Future<Map<String, String>> getClothingDetailsFromChatGPT(
      String imageUrl) async {
    return _analyzeClothingImage(
      imageUrl,
      systemPrompt: """
            You are a fashion AI assistant. Identify clothing details (type, brand, color, size) from images. Everything must be only from the available option.
            Select the **best matching values** from these predefined lists:

            - **Type:** ${types.join(", ")}
            - **Brand:** ${brands.join(", ")}
            - **Color:** ${colors.join(", ")}
            - **Size:** ${sizes.join(", ")}

            Return the response in the following **JSON format only**:
            {
              "type": "<best matching type>",
              "brand": "<best matching brand>",
              "color": "<best matching color>",
              "size": "<best matching size>",
              "description": "<3-4 words about the clothing>"
            }
            """,
      userInstruction:
          "Analyze this clothing image and return structured JSON.",
    );
  }

  Future<Map<String, String>> getOwnerPhotoClothingDetails(
    String imageUrl, {
    required String ownerHint,
    required bool ownerOnlyMode,
  }) async {
    return _analyzeClothingImage(
      imageUrl,
      systemPrompt: """
            You are a fashion AI assistant helping build a wardrobe from personal photos.
            Focus only on clothing worn by the PRIMARY SUBJECT who is most likely the phone owner.
            If there are multiple people, ignore everyone except the most central repeated owner candidate.
            If the clothing in the image does not confidently belong to the likely owner, return empty values and set ownerMatchConfidence low.
            Everything must be selected only from the available options.

            - **Type:** ${types.join(", ")}
            - **Brand:** ${brands.join(", ")}
            - **Color:** ${colors.join(", ")}
            - **Size:** ${sizes.join(", ")}

            Return the response in the following **JSON format only**:
            {
              "type": "<best matching type or empty>",
              "brand": "<best matching brand or empty>",
              "color": "<best matching color or empty>",
              "size": "<best matching size or empty>",
              "description": "<3-6 words about the clothing or empty>",
              "ownerMatchConfidence": "<number between 0 and 1>",
              "ownerReason": "<why this likely belongs to the phone owner or why it is uncertain>"
            }
            """,
      userInstruction: ownerOnlyMode
          ? "Analyze this personal photo and extract only the clothing worn by the likely phone owner. Owner hint: $ownerHint"
          : "Analyze this personal photo and extract clothing from the primary subject. Owner hint: $ownerHint",
    );
  }

  Future<Map<String, String>> _analyzeClothingImage(
    String imageUrl, {
    required String systemPrompt,
    required String userInstruction,
  }) async {
    try {
      if (_openAiApiKey.isEmpty) {
        print("Error: OPENAI_API_KEY is not configured.");
        return {};
      }

      final base64Image = await convertImageToBase64(imageUrl);
      if (base64Image.isEmpty) {
        print("Error: Image could not be converted to Base64.");
        return {};
      }

      final url = Uri.parse("https://api.openai.com/v1/chat/completions");

      final headers = {
        "Authorization": "Bearer $_openAiApiKey",
        "Content-Type": "application/json"
      };

      print("imageUrl: $imageUrl");

      final body = jsonEncode({
        "model": "gpt-4o",
        "messages": [
          {"role": "system", "content": systemPrompt},
          {
            "role": "user",
            "content": [
              {"type": "text", "text": userInstruction},
              {
                "type": "image_url",
                "image_url": {"url": "data:image/jpeg;base64,$base64Image"}
              }
            ]
          }
        ],
        "response_format": {"type": "json_object"},
        "max_tokens": 300
      });

      final response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        final aiResponse = ((jsonResponse['choices'] as List?)?.firstOrNull
            as Map<String, dynamic>?)?['message']?['content'];
        if (aiResponse == null) {
          print("Error: OpenAI response content was null.");
          return {};
        }
        print("AI Response: $aiResponse");
        return extractClothingDetails(aiResponse.toString());
      } else {
        print("Error: ${response.body}");
        return {};
      }
    } catch (e) {
      print("Error: $e");
      return {};
    }
  }

  /// **🔹 Extract structured details from AI response**
  Map<String, String> extractClothingDetails(String aiResponse) {
    print("aiResponse: $aiResponse");
    try {
      final Map<String, dynamic> json = jsonDecode(aiResponse);
      return {
        "type": _stringValue(json['type']),
        "brand": _stringValue(json['brand']),
        "color": _stringValue(json['color']),
        "size": _stringValue(json['size']),
        "description": _stringValue(json['description']),
        "ownerMatchConfidence": (json['ownerMatchConfidence'] ?? '').toString(),
        "ownerReason": _stringValue(json['ownerReason']),
      };
    } catch (e) {
      print("Error parsing AI response: $e");
      return {};
    }
  }

  String _stringValue(dynamic value) {
    if (value == null) {
      return '';
    }
    return value.toString();
  }
}
