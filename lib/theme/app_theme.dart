import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors - High-End 'Midnight' Palette (Simple, Creative, Professional)
  // Spacing Tokens
  static const double spacingExtraSmall = 4.0;
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 24.0;
  static const double spacingExtraLarge = 40.0;

  static const Color accentCyan = Color(0xFF00E5FF); // Sophisticated Sky Blue
  static const Color accentBlue = Color(0xFF38BDF8); // Soft Azure
  static const Color accentEmerald = Color(0xFF10B981);
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color darkBackground = Color(0xFF0F172A); // Rich Midnight Navy
  static const Color surfaceGrey = Color(0xFF1E293B); // Slate Surface

  static const LinearGradient brandGradient = LinearGradient(
    colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accentCyan,
        primary: accentCyan,
        secondary: accentBlue,
        surface: Colors.white,
        onSurface: darkBackground,
      ),
      scaffoldBackgroundColor: lightBackground,
      textTheme: _buildTextTheme(Brightness.light),
      appBarTheme: _buildAppBarTheme(Brightness.light),
      navigationBarTheme: _buildNavBarTheme(Brightness.light),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        brightness: Brightness.dark,
        seedColor: accentCyan,
        primary: accentCyan,
        secondary: accentBlue,
        surface: surfaceGrey,
        onSurface: Colors.white,
      ),
      scaffoldBackgroundColor: const Color.fromARGB(255, 22, 26, 34),
      textTheme: _buildTextTheme(Brightness.dark),
      appBarTheme: _buildAppBarTheme(Brightness.dark),
      navigationBarTheme: _buildNavBarTheme(Brightness.dark),
    );
  }

  static AppBarTheme _buildAppBarTheme(Brightness brightness) {
    return AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: brightness == Brightness.dark
            ? Brightness.light
            : Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: brightness == Brightness.dark
            ? Brightness.light
            : Brightness.dark,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
      iconTheme: IconThemeData(
        color: brightness == Brightness.light ? darkBackground : Colors.white,
      ),
      titleTextStyle: GoogleFonts.plusJakartaSans(
        color: brightness == Brightness.light ? darkBackground : Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  static NavigationBarThemeData _buildNavBarTheme(Brightness brightness) {
    return NavigationBarThemeData(
      backgroundColor: Colors.transparent,
      indicatorColor: accentCyan.withValues(alpha: 0.1),
      labelTextStyle: WidgetStateProperty.all(
        GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  static TextTheme _buildTextTheme(Brightness brightness) {
    final color = brightness == Brightness.light
        ? darkBackground
        : Colors.white;
    return TextTheme(
      displayLarge: GoogleFonts.plusJakartaSans(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: color,
      ),
      displayMedium: GoogleFonts.plusJakartaSans(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: color,
      ),
      headlineLarge: GoogleFonts.plusJakartaSans(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: color,
      ),
      headlineMedium: GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: color,
      ),
      titleLarge: GoogleFonts.plusJakartaSans(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      bodyLarge: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        color: color.withValues(alpha: 0.9),
      ),
      bodyMedium: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        color: color.withValues(alpha: 0.7),
      ),
    );
  }
}
