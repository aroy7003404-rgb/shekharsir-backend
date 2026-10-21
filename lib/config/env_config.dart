import 'package:flutter_dotenv/flutter_dotenv.dart';

class EnvConfig {
  static String get baseUrl =>
      dotenv.env['BASE_URL'] ?? 'https://shekharsir-backend.onrender.com';

  static String get appName =>
      dotenv.env['APP_NAME'] ?? 'Shekhar Sir Classes';

  static String get environment =>
      dotenv.env['ENVIRONMENT'] ?? 'production';

  static Future<void> init() async {
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {}
  }
}
