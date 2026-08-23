import 'package:flutter_test/flutter_test.dart';
import 'package:libris_app/core/services/search_history_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('saveSearch adds latest query to the front', () async {
    await SearchHistoryService.saveSearch('Dune');
    await SearchHistoryService.saveSearch('Clean Code');

    final recent = await SearchHistoryService.getRecentSearches();

    expect(recent.first, 'Clean Code');
    expect(recent.length, 2);
  });

  test('saveSearch keeps only the most recent 10 entries', () async {
    for (int i = 0; i < 12; i++) {
      await SearchHistoryService.saveSearch('Query $i');
    }

    final recent = await SearchHistoryService.getRecentSearches();

    expect(recent.length, 10);
    expect(recent.first, 'Query 11');
    expect(recent.last, 'Query 2');
  });
}
