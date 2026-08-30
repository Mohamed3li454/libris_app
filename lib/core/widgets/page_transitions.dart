import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

CustomTransitionPage<T> fadeSlidePage<T>({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: key,
    child: child,
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 240),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );

      // Adjust slide direction based on text directionality (LTR vs RTL)
      final isRtl = Directionality.of(context) == TextDirection.rtl;
      final beginOffset = Offset(isRtl ? -0.04 : 0.04, 0);

      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: beginOffset,
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// Custom page transition for modals/webview inspired by iOS Apple fluid motion:
/// - iOS Fluid Slide Up (Cubic(0.16, 1.0, 0.3, 1.0)) over 500ms
/// - iOS Fluid Slide Right (Cubic(0.25, 1.0, 0.5, 1.0)) over 420ms
CustomTransitionPage<T> fadeUpFadeRightPage<T>({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: key,
    child: child,
    transitionDuration: const Duration(milliseconds: 500),
    reverseTransitionDuration: const Duration(milliseconds: 420),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // Apple's signature fluid iOS modal curve
      const appleFluidEaseOut = Cubic(0.16, 1.0, 0.3, 1.0);
      const appleFluidEaseDismiss = Cubic(0.25, 1.0, 0.5, 1.0);

      final curvedForward = CurvedAnimation(
        parent: animation,
        curve: appleFluidEaseOut,
      );

      final curvedReverse = CurvedAnimation(
        parent: animation,
        curve: appleFluidEaseDismiss,
      );

      final isReversing = animation.status == AnimationStatus.reverse;

      // When opening: Fluid Slide up from bottom of the screen (0, 1.0) -> (0, 0)
      // When closing: Fluid Slide right off the screen (1.0, 0)
      final slideAnimation = isReversing
          ? Tween<Offset>(
              begin: const Offset(1.0, 0),
              end: Offset.zero,
            ).animate(curvedReverse)
          : Tween<Offset>(
              begin: const Offset(0, 1.0),
              end: Offset.zero,
            ).animate(curvedForward);

      final fadeAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(isReversing ? curvedReverse : curvedForward);

      return FadeTransition(
        opacity: fadeAnimation,
        child: SlideTransition(
          position: slideAnimation,
          child: child,
        ),
      );
    },
  );
}

