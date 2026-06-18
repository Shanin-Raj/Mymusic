import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Color Palette ───────────────────────────────────────────────────────────
class MyColors {
  // Backgrounds
  static const blackColor    = Color(0xFF111111);  // Home bg
  static const surfaceDark   = Color(0xFF121212);  // Card/screen bg
  static const cardColor     = Color(0xFF282828);  // Chip / card bg
  static const offWhite      = Color(0xFFF5F5F7);  // Light mode bg
  static const surfaceLight  = Color(0xFFFFFFFF);  // Light mode card

  // Text
  static const whiteColor    = Color(0xFFFFFFFF);
  static const lightGrey     = Color(0xFFB3B3B3);  // Secondary text
  static const mutedGrey     = Color(0xFF9C9C9C);  // Tertiary / hint text
  static const darkText      = Color(0xFF111111);  // Light mode primary text

  // Accent
  static const greenColor    = Color(0xFF1DB954);  // Spotify green (normal)
  static const greenBright   = Color(0xFF1ED760);  // Spotify green (bright, dark mode)

  // Progress / mini-player
  static const progressTrack = Color(0x44702E3C);  // Muted progress track tint
  static const divider       = Color(0xFF2A2A2A);  // Subtle divider
}

// ─── Typography ──────────────────────────────────────────────────────────────
// Montserrat — closest free Google Font to Spotify's "Spotify Mix" typeface.
// Both are geometric sans-serifs with similar proportions, weight range,
// and clean, modern character.
class AppTextStyles {
  // The font getter used everywhere — change this one line to switch font globally
  static TextStyle _base({
    double fontSize = 14,
    FontWeight fontWeight = FontWeight.w400,
    Color color = MyColors.whiteColor,
    double? letterSpacing,
    double? height,
  }) => GoogleFonts.montserrat(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    letterSpacing: letterSpacing,
    height: height,
  );

  // ── Section / Screen headers ─────────────────────────────────────────────
  static TextStyle greeting({Color color = MyColors.whiteColor}) =>
      _base(fontSize: 26, fontWeight: FontWeight.w800, color: color, letterSpacing: -0.5);

  static TextStyle sectionHeader({Color color = MyColors.whiteColor}) =>
      _base(fontSize: 22, fontWeight: FontWeight.w700, color: color, letterSpacing: -0.4);

  // ── Cards / Tiles ────────────────────────────────────────────────────────
  static TextStyle cardTitle({Color color = MyColors.whiteColor}) =>
      _base(fontSize: 15, fontWeight: FontWeight.w600, color: color, letterSpacing: -0.2);

  static TextStyle cardSubtitle({Color color = MyColors.lightGrey}) =>
      _base(fontSize: 13, fontWeight: FontWeight.w500, color: color);

  // ── Body text ────────────────────────────────────────────────────────────
  static TextStyle bodyBold({Color color = MyColors.whiteColor}) =>
      _base(fontSize: 16, fontWeight: FontWeight.w700, color: color);

  static TextStyle bodyRegular({Color color = MyColors.whiteColor}) =>
      _base(fontSize: 15, fontWeight: FontWeight.w500, color: color);

  // ── Navigation ───────────────────────────────────────────────────────────
  static TextStyle navLabel({Color color = MyColors.lightGrey}) =>
      _base(fontSize: 12, fontWeight: FontWeight.w600, color: color);

  // ── Now Playing ──────────────────────────────────────────────────────────
  static TextStyle nowPlayingTitle({Color color = MyColors.whiteColor}) =>
      _base(fontSize: 24, fontWeight: FontWeight.w800, color: color, letterSpacing: -0.5);

  static TextStyle nowPlayingArtist({Color color = MyColors.lightGrey}) =>
      _base(fontSize: 17, fontWeight: FontWeight.w500, color: color);

  // ── Search ───────────────────────────────────────────────────────────────
  static TextStyle searchHint({Color color = MyColors.lightGrey}) =>
      _base(fontSize: 16, fontWeight: FontWeight.w500, color: color);

  // ── Mini Player ──────────────────────────────────────────────────────────
  static TextStyle miniPlayerTitle({Color color = MyColors.whiteColor}) =>
      _base(fontSize: 14, fontWeight: FontWeight.w700, color: color);

  static TextStyle miniPlayerArtist({Color color = MyColors.lightGrey}) =>
      _base(fontSize: 12.5, fontWeight: FontWeight.w500, color: color);

  // ── Utility: timestamps, badges, small labels ────────────────────────────
  static TextStyle caption({Color color = MyColors.mutedGrey}) =>
      _base(fontSize: 12, fontWeight: FontWeight.w500, color: color);

  static TextStyle tagLabel({Color color = MyColors.mutedGrey}) =>
      _base(fontSize: 11, fontWeight: FontWeight.w600, color: color, letterSpacing: 1.0);
}
