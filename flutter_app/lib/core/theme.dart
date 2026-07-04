import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SonicTheme {
  // Brand Colors
  static const Color sonicGreen = Color(0xFF1DB954);
  static const Color darkBackground = Color(0xFF121212); // Standard Spotify-like deep dark
  static const Color darkSurface = Color(0xFF1E1E1E); // Elevated surfaces
  static const Color lightBackground = Color(0xFFF6F6F6); // Soft light grey/white
  static const Color lightSurface = Color(0xFFFFFFFF);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: sonicGreen,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: const ColorScheme.dark(
        primary: sonicGreen,
        secondary: sonicGreen,
        surface: darkSurface,
      ),
      textTheme: GoogleFonts.montserratTextTheme(ThemeData.dark().textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: darkBackground,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
      ),
      cardTheme: CardThemeData(
        color: darkSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: sonicGreen,
      scaffoldBackgroundColor: lightBackground,
      colorScheme: const ColorScheme.light(
        primary: sonicGreen,
        secondary: sonicGreen,
        surface: lightSurface,
      ),
      textTheme: GoogleFonts.montserratTextTheme(ThemeData.light().textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Colors.black),
        titleTextStyle: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: lightBackground,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
      ),
      cardTheme: CardThemeData(
        color: lightSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
