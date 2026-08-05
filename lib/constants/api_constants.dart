import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  ApiConstants._();

  static String get apiKey => dotenv.env['API_KEY'] ?? '';
}
