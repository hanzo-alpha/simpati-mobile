import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ─── Web Match Palette (Mist + Emerald) ─────────────
  static const Color slate950 = Color(0xFF0B0F19);
  static const Color slate900 = Color(0xFF0F172A);
  static const Color slate800 = Color(0xFF1E293B);
  static const Color slate700 = Color(0xFF334155);
  static const Color slate600 = Color(0xFF475569);

  // Emerald Primary Palette (Matching Web --primary hsl(158 64% 40%))
  static const Color emerald500 = Color(0xFF10B981);
  static const Color emerald600 = Color(0xFF0D9488);
  static const Color emerald700 = Color(0xFF047857);

  // Status & Utility Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Legacy Alias Compatibility
  static const Color navy900 = slate900;
  static const Color navy800 = slate800;
  static const Color navy700 = slate700;
  static const Color navy600 = slate600;

  static const Color teal400 = Color(0xFF34D399);
  static const Color teal500 = emerald500;
  static const Color teal600 = emerald600;
  static const Color teal700 = emerald700;
  static const Color teal800 = Color(0xFF065F46);

  // ─── Theme-Aware Helpers ───────────────────────
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  // Backgrounds
  static Color bgPrimary(BuildContext context) =>
      isDark(context) ? slate900 : const Color(0xFFF8FAFC);

  static Color bgSecondary(BuildContext context) =>
      isDark(context) ? slate800 : Colors.white;

  static Color bgCard(BuildContext context) =>
      isDark(context) ? slate800 : Colors.white;

  static Color bgGlass(BuildContext context) => isDark(context)
      ? Colors.white.withAlpha(12)
      : Colors.white.withAlpha(190);

  static Color bgGlassBorder(BuildContext context) =>
      isDark(context) ? Colors.white.withAlpha(24) : Colors.black.withAlpha(10);

  // Header / AppBar backgrounds (Matches Web Slate -> Emerald gradient)
  static List<Color> headerGradient(BuildContext context) => isDark(context)
      ? [slate950, slate900]
      : [const Color(0xFF0F172A), const Color(0xFF0D9488)];

  // Text
  static Color textPrimary(BuildContext context) =>
      isDark(context) ? const Color(0xFFF8FAFC) : const Color(0xFF0F172A);

  static Color textSecondary(BuildContext context) =>
      isDark(context) ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

  static Color textMuted(BuildContext context) =>
      isDark(context) ? const Color(0xFF64748B) : const Color(0xFF94A3B8);

  // Nav bar
  static Color navBarBg(BuildContext context) =>
      isDark(context) ? slate800.withAlpha(235) : Colors.white.withAlpha(245);

  static Color navBarInactiveIcon(BuildContext context) =>
      isDark(context) ? const Color(0xFF64748B) : const Color(0xFF94A3B8);

  static Color navBarInactiveText(BuildContext context) =>
      isDark(context) ? const Color(0xFF64748B) : const Color(0xFF64748B);

  // Divider & Borders
  static Color dividerColor(BuildContext context) =>
      isDark(context) ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

  // ─── Light Theme Data (Web Aligned) ─────────────
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      colorScheme: const ColorScheme.light(
        primary: emerald600,
        secondary: emerald500,
        surface: Colors.white,
        error: danger,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: slate900),
        titleTextStyle: TextStyle(
          color: slate900,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: emerald600,
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
          borderSide: const BorderSide(color: emerald600, width: 2),
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
        shadowColor: Colors.black.withAlpha(15),
      ),
    );
  }

  // ─── Dark Theme Data (Web Mist Dark Aligned) ───
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: slate900,
      colorScheme: const ColorScheme.dark(
        primary: emerald500,
        secondary: emerald600,
        surface: slate800,
        error: danger,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: emerald600,
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
        fillColor: slate800.withAlpha(180),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: slate700),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: slate700),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: emerald500, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      cardTheme: CardThemeData(
        color: slate800,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        elevation: 0,
      ),
    );
  }
}
