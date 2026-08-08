import 'package:flutter/material.dart';

class OnboardingModel {
  final String title;
  final String subtitle;
  final IconData icon;
  final String badgeText;

  const OnboardingModel({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.badgeText,
  });
}
