import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libris_app/core/widgets/custom_bottom_navigation_bar.dart';

void main() {
  testWidgets('Bottom navigation shows Home, Explore, and Library', (
    WidgetTester tester,
  ) async {
    var selected = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: CustomBottomNavigationBar(
            selectedIndex: selected,
            onItemTapped: (index) {
              selected = index;
            },
          ),
        ),
      ),
    );

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Explore'), findsOneWidget);
    expect(find.text('Library'), findsOneWidget);
    expect(find.text('Profile'), findsNothing);

    await tester.tap(find.text('Explore'));
    await tester.pump();
    expect(selected, 1);

    await tester.tap(find.text('Library'));
    await tester.pump();
    expect(selected, 2);
  });
}
