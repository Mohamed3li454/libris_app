import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:libris_app/core/services/onboarding_service.dart';
import 'package:libris_app/features/onboarding/presentation/view/onboarding_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OnboardingService Tests', () {
    test('isFirstTimeUser returns true by default', () async {
      SharedPreferences.setMockInitialValues({});
      final isFirstTime = await OnboardingService.isFirstTimeUser();
      expect(isFirstTime, isTrue);
    });

    test('setFirstTimeUserComplete sets isFirstTimeUser to false', () async {
      SharedPreferences.setMockInitialValues({});
      await OnboardingService.setFirstTimeUserComplete();
      final isFirstTime = await OnboardingService.isFirstTimeUser();
      expect(isFirstTime, isFalse);
    });
  });

  group('OnboardingView Widget Tests', () {
    testWidgets('renders onboarding slides, skip button and page indicator', (WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});

      await tester.pumpWidget(
        const MaterialApp(
          home: OnboardingView(),
        ),
      );

      // Verify initial slide content
      expect(find.text('Discover Great Books'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
      expect(find.text('DISCOVER'), findsOneWidget);

      // Swipe to next slide
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('Read & Download'), findsOneWidget);
      expect(find.text('READ'), findsOneWidget);

      // Swipe to final slide
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('Build Your Library'), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);
      expect(find.text('LIBRARY'), findsOneWidget);
    });
  });
}
