import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String get baseUrl {
    // Always use dotenv value for API_BASE_URL
    return dotenv.env['API_BASE_URL'] ?? '';
  }

  // All URLs are now loaded from .env
}
