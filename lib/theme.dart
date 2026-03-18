import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const bg = Color(0xFF08090C);
  static const sur = Color(0xFF0F1117);
  static const sur2 = Color(0xFF161820);
  static const sur3 = Color(0xFF1E2028);
  static const bdr = Color(0xFF252830);
  static const bdr2 = Color(0xFF2E3140);
  static const txt = Color(0xFFE8EAF2);
  static const txt2 = Color(0xFFA8ABBE);
  static const mut = Color(0xFF55596E);
  static const mut2 = Color(0xFF383C4E);

  static const acc = Color(0xFF6366F1);
  static const acc2 = Color(0x1F6366F1);
  static const acc3 = Color(0x0F6366F1);
  static const amber = Color(0xFFF59E0B);
  static const grn = Color(0xFF22D3A5);
  static const grn2 = Color(0x1A22D3A5);
  static const blu = Color(0xFF818CF8);
  static const blu2 = Color(0x1A818CF8);
  static const red = Color(0xFFF97316);
  static const red2 = Color(0x1AF97316);
  static const dan = Color(0xFFEF4444);
}

class AppTheme {
  static TextStyle display({double size = 22, FontWeight weight = FontWeight.w600, Color color = AppColors.txt}) {
    return GoogleFonts.syne(fontSize: size, fontWeight: weight, color: color);
  }

  static TextStyle ui({double size = 14, FontWeight weight = FontWeight.w400, Color color = AppColors.txt}) {
    return GoogleFonts.dmSans(fontSize: size, fontWeight: weight, color: color);
  }

  static TextStyle mono({double size = 12, FontWeight weight = FontWeight.w400, Color color = AppColors.mut}) {
    return GoogleFonts.jetBrainsMono(fontSize: size, fontWeight: weight, color: color);
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.acc,
        surface: AppColors.sur,
        error: AppColors.dan,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.sur,
        elevation: 0,
        titleTextStyle: display(size: 22),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.bdr),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.bdr),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.acc),
        ),
        hintStyle: ui(color: AppColors.mut2),
        labelStyle: mono(size: 10, color: AppColors.mut),
      ),
    );
  }

  static InputDecoration fieldDecoration(String hint, {String? label}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: ui(color: AppColors.mut2, size: 13),
      labelText: label,
      labelStyle: mono(size: 10, color: AppColors.mut),
      filled: true,
      fillColor: AppColors.bg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.bdr),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.bdr),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.acc),
      ),
    );
  }
}
