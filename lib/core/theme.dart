import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Brand colors (constant — same in both themes) ─────────────────────────
class AppColors {
  static const Color primary    = Color(0xFF22C55E);
  static const Color secondary  = Color(0xFF16A34A);
  static const Color success    = Color(0xFF2ECC71);
  static const Color warning    = Color(0xFFF39C12);
  static const Color danger     = Color(0xFFE74C3C);
  static const Color navActive  = Color(0xFF22C55E);
  static const Color navInactive = Color(0xFF9CA3AF);

  // Light-mode semantic constants (used as fallback)
  static const Color textPrimary   = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF475569);
  static const Color background    = Color(0xFFF0F4F8);
  static const Color cardBackground = Color(0xFFFFFFFF);
}

// ── Dynamic helpers — call these instead of hardcoded colors ─────────────
// Usage:  AppThemeHelper.cardColor(context)
class AppThemeHelper {
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  // Background
  static Color scaffoldBg(BuildContext context) =>
      isDark(context) ? const Color(0xFF0F0F0F) : const Color(0xFFF0F4F8);

  // Card / surface
  static Color cardColor(BuildContext context) =>
      isDark(context) ? const Color(0xFF1C1C1E) : Colors.white;

  // Sub-surface (input fields, inner containers)
  static Color surfaceColor(BuildContext context) =>
      isDark(context) ? const Color(0xFF2C2C2E) : const Color(0xFFF8FAFC);

  // Section / tile background
  static Color tileBg(BuildContext context) =>
      isDark(context) ? const Color(0xFF1C1C1E) : Colors.white;

  // Border
  static Color borderColor(BuildContext context) =>
      isDark(context) ? const Color(0xFF38383A) : const Color(0xFFE5E7EB);

  // Divider
  static Color dividerColor(BuildContext context) =>
      isDark(context) ? const Color(0xFF38383A) : const Color(0xFFE5E7EB);

  // Primary text
  static Color textPrimary(BuildContext context) =>
      isDark(context) ? const Color(0xFFF2F2F7) : const Color(0xFF0F172A);

  // Secondary / muted text
  static Color textSecondary(BuildContext context) =>
      isDark(context) ? const Color(0xFF8E8E93) : const Color(0xFF64748B);

  // Icon muted
  static Color iconMuted(BuildContext context) =>
      isDark(context) ? const Color(0xFF636366) : Colors.grey;

  // Shadow
  static Color shadowColor(BuildContext context) =>
      isDark(context)
          ? Colors.black.withValues(alpha: 0.4)
          : Colors.black.withValues(alpha: 0.06);

  // Input fill
  static Color inputFill(BuildContext context) =>
      isDark(context) ? const Color(0xFF2C2C2E) : Colors.white;

  // AppBar background (always primary green, consistent across both themes)
  static const Color appBarBg = AppColors.primary;
}

// ── Light Theme ───────────────────────────────────────────────────────────
class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: const Color(0xFFF0F4F8),
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: Colors.white,
        brightness: Brightness.light,
      ),
      textTheme: GoogleFonts.interTextTheme().copyWith(
        displayLarge: GoogleFonts.inter(color: const Color(0xFF0F172A), fontWeight: FontWeight.bold),
        bodyLarge:    GoogleFonts.inter(color: const Color(0xFF0F172A)),
        bodyMedium:   GoogleFonts.inter(color: const Color(0xFF64748B)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      dividerColor: const Color(0xFFE5E7EB),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.primary,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.navInactive,
        elevation: 12,
      ),
    );
  }

  // ── Dark Theme ────────────────────────────────────────────────────────
  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: const Color(0xFF0F0F0F),
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        surface: const Color(0xFF1C1C1E),
        brightness: Brightness.dark,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
        displayLarge: GoogleFonts.inter(color: const Color(0xFFF2F2F7), fontWeight: FontWeight.bold),
        bodyLarge:    GoogleFonts.inter(color: const Color(0xFFF2F2F7)),
        bodyMedium:   GoogleFonts.inter(color: const Color(0xFF8E8E93)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF2C2C2E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF38383A)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF38383A)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        hintStyle: const TextStyle(color: Color(0xFF636366)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1C1C1E),
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF38383A), width: 0.5),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      dividerColor: const Color(0xFF38383A),
      listTileTheme: const ListTileThemeData(
        iconColor: AppColors.primary,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF1C1C1E),
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Color(0xFF636366),
        elevation: 0,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF1C1C1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF38383A)),
        ),
      ),
    );
  }
}

// ── Theme State Provider ──────────────────────────────────────────────────
class ThemeNotifier extends Notifier<ThemeMode> {
  static const _storage = FlutterSecureStorage();
  static const _key = 'theme_mode';

  @override
  ThemeMode build() {
    _loadFromStorage();
    return ThemeMode.light;
  }

  Future<void> _loadFromStorage() async {
    try {
      final saved = await _storage.read(key: _key);
      if (saved == 'dark') {
        state = ThemeMode.dark;
      } else if (saved == 'light') {
        state = ThemeMode.light;
      }
    } catch (_) {
      // Fallback to light
    }
  }

  Future<void> toggleTheme(bool isDark) async {
    state = isDark ? ThemeMode.dark : ThemeMode.light;
    try {
      await _storage.write(key: _key, value: isDark ? 'dark' : 'light');
    } catch (_) {}
  }

  bool get isDark => state == ThemeMode.dark;
}

final themeProvider = NotifierProvider<ThemeNotifier, ThemeMode>(ThemeNotifier.new);
