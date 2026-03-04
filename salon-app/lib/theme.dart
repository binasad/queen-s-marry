import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const Color kPrimary = Color(0xFFFF6CBF);
const Color kPrimaryDark = Color(0xFFdb2777);
const Color kBackground = Color(0xFFFDF2F8);

TextTheme _buildTextTheme() {
  // Josefin Sans for headings, Poppins for body
  final poppinsBase = GoogleFonts.poppinsTextTheme();

  return poppinsBase.copyWith(
    // Headings → Josefin Sans
    displayLarge: GoogleFonts.josefinSans(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.5,
    ),
    displayMedium: GoogleFonts.josefinSans(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.5,
    ),
    displaySmall: GoogleFonts.josefinSans(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.3,
    ),
    headlineLarge: GoogleFonts.josefinSans(
      fontSize: 22,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.3,
    ),
    headlineMedium: GoogleFonts.josefinSans(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.2,
    ),
    headlineSmall: GoogleFonts.josefinSans(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.2,
    ),
    titleLarge: GoogleFonts.josefinSans(
      fontSize: 17,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.15,
    ),
    titleMedium: GoogleFonts.josefinSans(
      fontSize: 15,
      fontWeight: FontWeight.w600,
    ),
    titleSmall: GoogleFonts.josefinSans(
      fontSize: 14,
      fontWeight: FontWeight.w500,
    ),

    // Body → Poppins (already set by poppinsBase, just ensure sizes)
    bodyLarge: GoogleFonts.poppins(
      fontSize: 16,
      fontWeight: FontWeight.w400,
    ),
    bodyMedium: GoogleFonts.poppins(
      fontSize: 14,
      fontWeight: FontWeight.w400,
    ),
    bodySmall: GoogleFonts.poppins(
      fontSize: 12,
      fontWeight: FontWeight.w400,
    ),
    labelLarge: GoogleFonts.poppins(
      fontSize: 14,
      fontWeight: FontWeight.w500,
    ),
    labelMedium: GoogleFonts.poppins(
      fontSize: 12,
      fontWeight: FontWeight.w500,
    ),
    labelSmall: GoogleFonts.poppins(
      fontSize: 11,
      fontWeight: FontWeight.w400,
    ),
  );
}

ThemeData buildAppTheme() {
  final textTheme = _buildTextTheme();

  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: kPrimary,
      primary: kPrimary,
      secondary: kPrimaryDark,
      surface: Colors.white,
    ),
    textTheme: textTheme,
    primaryColor: kPrimary,
    scaffoldBackgroundColor: Colors.white,

    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black87,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.josefinSans(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: Colors.black87,
        letterSpacing: 0.3,
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        textStyle: GoogleFonts.poppins(
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      labelStyle: GoogleFonts.poppins(fontSize: 14),
      hintStyle: GoogleFonts.poppins(fontSize: 14, color: Colors.grey),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: kPrimary, width: 2),
      ),
    ),

    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      selectedItemColor: kPrimary,
      unselectedItemColor: Colors.grey,
    ),
  );
}
