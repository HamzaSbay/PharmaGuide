import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// PharmaGuide TN Design System
/// Base Palette: White, Pharmacy Green, Deep Sleek Black
class AppTheme {
  // ── 3 Base Colors ──────────────────────────
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color pharmacyGreen = Color(0xFF00A859); // Vibrant Tunisian Pharmacy Green
  static const Color deepBlack = Color(0xFF0F172A); // High-contrast Deep Black

  // ── Tonal System Variants ─────────────────
  static const Color lightGreen = Color(0xFFE8F5E9); // Light green highlight
  static const Color emeraldDark = Color(0xFF007A40); // Darker green accent
  static const Color softGreyBg = Color(0xFFF8FAFC); // Clean off-white background
  static const Color borderGrey = Color(0xFFE2E8F0); // Subtly defined borders
  static const Color textMuted = Color(0xFF64748B); // Slate secondary text
  static const Color errorRed = Color(0xFFDC2626); // Clean red alert

  // Legacy mappings for backwards compatibility
  static const Color primaryTeal = deepBlack;
  static const Color primaryDark = deepBlack;
  static const Color secondaryEmerald = pharmacyGreen;
  static const Color accentAmber = Color(0xFFD97706);
  static const Color cnamBlue = Color(0xFF0284C7);
  static const Color gardePurple = Color(0xFF7C3AED);
  static const Color darkSlate = deepBlack;
  static const Color lightBg = softGreyBg;
  static const Color cardBg = pureWhite;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: pharmacyGreen,
        secondary: deepBlack,
        surface: pureWhite,
        error: errorRed,
        onPrimary: pureWhite,
        onSecondary: pureWhite,
        onSurface: deepBlack,
      ),
      scaffoldBackgroundColor: softGreyBg,
      textTheme: GoogleFonts.interTextTheme(),
      appBarTheme: AppBarTheme(
        backgroundColor: deepBlack,
        foregroundColor: pureWhite,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: pureWhite,
          letterSpacing: 0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: pureWhite,
        elevation: 2,
        shadowColor: deepBlack.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: borderGrey, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: pharmacyGreen,
          foregroundColor: pureWhite,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            letterSpacing: 0.3,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: deepBlack,
          side: const BorderSide(color: deepBlack, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.dark(
        primary: pharmacyGreen,
        secondary: pureWhite,
        surface: deepBlack,
        error: errorRed,
        onPrimary: pureWhite,
        onSecondary: deepBlack,
        onSurface: pureWhite,
      ),
      scaffoldBackgroundColor: deepBlack,
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      appBarTheme: AppBarTheme(
        backgroundColor: deepBlack,
        foregroundColor: pureWhite,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: pureWhite,
          letterSpacing: 0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1E293B),
        elevation: 2,
        shadowColor: pureWhite.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFF334155), width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: pharmacyGreen,
          foregroundColor: pureWhite,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            letterSpacing: 0.3,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: pureWhite,
          side: const BorderSide(color: pureWhite, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
