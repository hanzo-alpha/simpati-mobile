import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ─── Colors ────────────────────────────────────
  static const Color navy900 = Color(0xFF0A0E27);
  static const Color navy800 = Color(0xFF0F1535);
  static const Color navy700 = Color(0xFF151D44);
  static const Color navy600 = Color(0xFF1B2654);

  static const Color teal400 = Color(0xFF3ED6F5);
  static const Color teal500 = Color(0xFF0DCCF2);
  static const Color teal600 = Color(0xFF0AB0D1);
  static const Color teal700 = Color(0xFF0894B0);
  static const Color teal800 = Color(0xFF06788F);

  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // ─── Theme-Aware Helpers ───────────────────────
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  // Backgrounds
  static Color bgPrimary(BuildContext context) =>
      isDark(context) ? navy900 : const Color(0xFFF8FAFC);
  static Color bgSecondary(BuildContext context) =>
      isDark(context) ? navy800 : Colors.white;
  static Color bgCard(BuildContext context) =>
      isDark(context) ? navy800 : Colors.white;
  static Color bgGlass(BuildContext context) => isDark(context)
      ? Colors.white.withAlpha(10)
      : Colors.white.withAlpha(180);
  static Color bgGlassBorder(BuildContext context) =>
      isDark(context) ? Colors.white.withAlpha(20) : Colors.black.withAlpha(8);

  // Header / AppBar backgrounds
  static List<Color> headerGradient(BuildContext context) => isDark(context)
      ? [navy800, navy900]
      : [const Color(0xFF0A7C96), const Color(0xFF0DCCF2)];

  // Text
  static Color textPrimary(BuildContext context) =>
      isDark(context) ? Colors.white : const Color(0xFF1E293B);
  static Color textSecondary(BuildContext context) =>
      isDark(context) ? Colors.grey.shade400 : Colors.grey.shade600;
  static Color textMuted(BuildContext context) =>
      isDark(context) ? Colors.white70 : Colors.grey.shade500;

  // Nav bar
  static Color navBarBg(BuildContext context) =>
      isDark(context) ? navy800.withAlpha(220) : Colors.white.withAlpha(240);
  static Color navBarInactiveIcon(BuildContext context) =>
      isDark(context) ? Colors.grey.shade500 : Colors.grey.shade400;
  static Color navBarInactiveText(BuildContext context) =>
      isDark(context) ? Colors.grey.shade600 : Colors.grey.shade500;

  // Divider
  static Color dividerColor(BuildContext context) =>
      isDark(context) ? Colors.white24 : Colors.black12;

  // ─── Theme Data ────────────────────────────────
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      colorScheme: const ColorScheme.light(
        primary: teal600,
        secondary: teal500,
        surface: Colors.white,
        error: danger,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: navy900),
        titleTextStyle: TextStyle(
          color: navy900,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: teal600,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: teal600, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 2,
        shadowColor: Colors.black.withAlpha(20),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: navy900,
      colorScheme: const ColorScheme.dark(
        primary: teal500,
        secondary: teal600,
        surface: navy800,
        error: danger,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: teal500,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: navy800.withAlpha(128),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: navy600),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: navy600),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: teal500, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      cardTheme: CardThemeData(
        color: navy800.withAlpha(100),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
      ),
    );
  }
}
