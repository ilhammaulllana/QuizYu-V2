import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF8FAFC), // Putih keabu-abuan bersih
      primaryColor: const Color(0xFF7F5AF0), // Ungu elektrik
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF7F5AF0),
        secondary: Color(0xFF10B981), // Hijau zamrud
        error: Color(0xFFEF4565), // Merah cerah
        surface: Colors.white, // Kartu putih bersih
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Color(0xFF0F172A), // Teks abu-abu gelap
      ),
      textTheme: GoogleFonts.outfitTextTheme(
        ThemeData.light().textTheme.apply(
              bodyColor: const Color(0xFF1E293B), // Teks isi abu-abu gelap
              displayColor: const Color(0xFF0F172A), // Judul teks ekstra gelap
            ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5), // Garis tepi abu-abu lembut
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF7F5AF0), width: 2),
        ),
        labelStyle: const TextStyle(color: Color(0xFF64748B)),
        hintStyle: const TextStyle(color: Color(0xFF94A1B2)),
      ),
      useMaterial3: true,
    );
  }
}
