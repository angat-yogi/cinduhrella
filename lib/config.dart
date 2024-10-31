// class Config {
//   static const String removeBgApiKey = 'ZM9TtVdxwdpjFi9aGSLubs5h';
//   static const String url = 'https://api.remove.bg/v1.0/removebg';

// }
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Config {
  // Use `final` instead of `const`
  static String get removeBgApiKey => dotenv.env['REMOVE_BG_API_KEY'] ?? '';
  static String get url => dotenv.env['REMOVE_BG_URL'] ?? '';
}
