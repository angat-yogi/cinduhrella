import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';
import 'package:cinduhrella/services/database_service.dart';

class ChatService {
  late DatabaseService _databaseService;
  final GetIt _getIt = GetIt.instance;
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
  ChatService() {
    _databaseService = _getIt.get<DatabaseService>();
  }
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
    try {
      // Convert image to Base64
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
          {
            "role": "system",
            "content": """
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
            """
          },
          {
            "role": "user",
            "content": [
              {
                "type": "text",
                "text":
                    "Analyze this clothing image and return structured JSON."
              },
              {
                "type": "image_url",
                "image_url": {
                  "url":
                      "data:image/jpeg;base64,$base64Image" // ✅ Proper Base64 format
                }
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
        final String aiResponse =
            jsonResponse['choices'][0]['message']['content'];
        print("AI Response: $aiResponse");
        return extractClothingDetails(aiResponse);
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
        "type": json['type'] ?? "",
        "brand": json['brand'] ?? "",
        "color": json['color'] ?? "",
        "size": json['size'] ?? "",
        "description": json['description'] ?? ""
      };
    } catch (e) {
      print("Error parsing AI response: $e");
      return {};
    }
  }
}
