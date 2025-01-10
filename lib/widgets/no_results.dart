import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shoppinglistai/constants.dart';

class NoResults extends StatelessWidget {
  const NoResults({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 64,
            color: AppColors.darkGrey,
          ),
          const SizedBox(height: 16),
          Text(
            'Sonuç bulunamadı',
            style: GoogleFonts.ubuntu(
              fontSize: 18,
              color: AppColors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }
}
