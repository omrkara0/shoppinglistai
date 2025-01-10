import 'package:flutter/material.dart';

const List<String> miktarTurleri = [
  "kilo",
  "adet",
  "litre",
  "tane",
  "paket",
  "kutu",
  "poşet",
  "şişe",
  "gram"
];

class AppColors {
  static const Color darkBackground = Color(0xFF222831);
  static const Color darkGrey = Color(0xFF393E46);
  static const Color accent = Color(0xFF00ADB5);
  static const Color lightGrey = Color(0xFFEEEEEE);

  // Accent color with opacity
  static Color accentWithOpacity(double opacity) => accent.withOpacity(opacity);

  // Text colors
  static const Color primaryText = darkBackground;
  static const Color secondaryText = darkGrey;
  static const Color lightText = lightGrey;

  // Background variations
  static const Color scaffoldBackground = lightGrey;
  static const Color cardBackground = Colors.white;
  static Color selectedCardBackground = accent.withOpacity(0.1);
}
