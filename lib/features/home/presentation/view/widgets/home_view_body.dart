import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:libris_app/constants/app_colors.dart';

class HomeViewBody extends StatelessWidget {
  const HomeViewBody({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Libris",
                  style: GoogleFonts.inter(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 32,
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: Icon(Icons.search, size: 32, color: AppColors.primary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
