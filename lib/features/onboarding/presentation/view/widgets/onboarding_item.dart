import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:libris_app/constants/app_colors.dart';
import 'package:libris_app/features/onboarding/data/models/onboarding_model.dart';

class OnboardingItem extends StatelessWidget {
  final OnboardingModel model;

  const OnboardingItem({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Illustration / Graphic Container
          Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.08),
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.4),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  blurRadius: 30,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Center(
              child: Container(
                width: 170,
                height: 170,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.15),
                      AppColors.accent.withValues(alpha: 0.25),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Icon(
                  model.icon,
                  size: 84,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),

          // Badge tag
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              model.badgeText,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Title
          Text(
            model.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.playfairDisplay(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),

          // Subtitle
          Text(
            model.subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: AppColors.secondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
