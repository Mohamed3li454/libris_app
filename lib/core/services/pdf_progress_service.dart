import 'package:shared_preferences/shared_preferences.dart';

class PdfProgressService {
  PdfProgressService._();

  static const String _prefix = 'pdf_last_page_';

  static Future<int> getLastPage(String bookId) async {
    if (bookId.isEmpty) return 1;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('$_prefix$bookId') ?? 1;
  }

  static Future<void> saveLastPage(String bookId, int page) async {
    if (bookId.isEmpty || page < 1) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$_prefix$bookId', page);
  }
}
