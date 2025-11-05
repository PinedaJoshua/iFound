import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Define Colors
  static const Color primaryColor = Color(0xFF141449);
  static const Color secondaryColor = Color(0xFFFBB313);
  static const Color lightTextColor = Colors.grey;
  static const Color darkTextColor = Colors.black;
  static const Color backgroundColor = Colors.white;

  // Define Text Themes
  static ThemeData get theme {
    return ThemeData(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,

      // FIX 5: Applied global font theme
      textTheme: TextTheme(
        // Headers
        headlineMedium: GoogleFonts.leagueSpartan(
          fontWeight: FontWeight.bold,
          color: primaryColor,
          fontSize: 28,
        ),
        titleLarge: GoogleFonts.leagueSpartan(
          fontWeight: FontWeight.bold,
          color: primaryColor,
          fontSize: 22,
        ),
        
        // Subheaders / Paragraphs
        bodyMedium: GoogleFonts.inter(
          fontSize: 16,
          color: darkTextColor.withOpacity(0.7),
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 14,
          color: lightTextColor,
        ),

        // Default text
        labelLarge: GoogleFonts.inter(),
      ),
      
      // Define App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: primaryColor),
        // FIX 5: Applied font to AppBar titles
        titleTextStyle: GoogleFonts.leagueSpartan(
          color: primaryColor,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),

      // Define Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30.0),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          // FIX 5: Applied font to buttons
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // Define Input Field Theme
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        labelStyle: const TextStyle(color: lightTextColor),
      ),
    );
  }
}