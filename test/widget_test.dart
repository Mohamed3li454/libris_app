import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libris_app/features/main/presentation/view/main_navigation_view.dart';

void main() {
  testWidgets(
      'MainNavigationView defaults to Home and switches views on tab tap',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MainNavigationView(),
      ),
    );

    // Verify Home tab is selected by default (index 0)
    expect(find.text('The Great Gatsby'), findsWidgets);

    // Tap Explore tab
    await tester.tap(find.text('Explore'));
    await tester.pumpAndSettle();
    expect(find.text('Explore Content Coming Soon'), findsOneWidget);

    // Tap Library tab
    await tester.tap(find.text('Library'));
    await tester.pumpAndSettle();
    expect(find.text('Your Library is Empty'), findsOneWidget);

    // Tap Profile tab
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Profile Settings'), findsOneWidget);
  });
}
