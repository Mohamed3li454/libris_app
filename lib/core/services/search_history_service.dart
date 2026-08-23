import 'package:shared_preferences/shared_preferences.dart';

class SearchHistoryService {
  SearchHistoryService._();

  static const String _recentSearchesKey = 'recent_searches';
  static const int _maxItems = 10;

  static Future<List<String>> getRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_recentSearchesKey) ?? <String>[];
  }

  static Future<void> saveSearch(String query) async {
    final clean = query.trim();
    if (clean.isEmpty || clean.length < 3) return;

    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_recentSearchesKey) ?? <String>[];
    current.removeWhere((item) => item.toLowerCase() == clean.toLowerCase());
    current.insert(0, clean);

    if (current.length > _maxItems) {
      current.removeRange(_maxItems, current.length);
    }

    await prefs.setStringList(_recentSearchesKey, current);
  }

  static Future<void> clearRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_recentSearchesKey);
  }
}
