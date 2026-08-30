import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libris_app/core/widgets/app_dialog.dart';

void main() {
  testWidgets('AppDialog shows success toast and can be dismissed', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  AppDialog.success(
                    context,
                    title: 'Success',
                    message: 'Added to your Library',
                  );
                },
                child: const Text('Show Success'),
              );
            },
          ),
        ),
      ),
    );

    // Tap button to show dialog
    await tester.tap(find.text('Show Success'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Success'), findsOneWidget);
    expect(find.text('Added to your Library'), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);

    // Tap toast to dismiss
    await tester.tap(find.text('Added to your Library'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Added to your Library'), findsNothing);
  });

  testWidgets('AppDialog shows error toast and auto-dismisses', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  AppDialog.error(
                    context,
                    message: 'Unable to open link',
                    duration: const Duration(milliseconds: 500),
                  );
                },
                child: const Text('Show Error'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show Error'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Unable to open link'), findsOneWidget);
    expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);

    // Wait for auto dismiss
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Unable to open link'), findsNothing);
  });

  testWidgets('AppDialog shows info toast without title', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  AppDialog.info(
                    context,
                    message: 'Reader link not available yet',
                  );
                },
                child: const Text('Show Info'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show Info'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Reader link not available yet'), findsOneWidget);
    expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);

    unawaited(AppDialog.dismiss());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    expect(find.text('Reader link not available yet'), findsNothing);
  });
}
