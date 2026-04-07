import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Colors
  static const Color accentIndigo = Color(0xFF6366F1); // Modern Indigo
  static const Color accentTeal = Color(0xFF14B8A6);   // To compliment
  static const Color lightGrey = Color(0xFFF9FAFB);
  static const Color darkGrey = Color(0xFF111827);    // Deep Slate
  static const Color surfaceGrey = Color(0xFF1F2937); // For Cards
  
  static const LinearGradient brandGradient = LinearGradient(
    colors: [accentIndigo, Color(0xFF4F46E5)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accentIndigo,
        primary: accentIndigo,
        secondary: accentTeal,
        surface: Colors.white,
        onSurface: darkGrey,
      ),
      scaffoldBackgroundColor: Colors.white,
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
        seedColor: accentIndigo,
        primary: accentIndigo,
        secondary: accentTeal,
        surface: surfaceGrey,
        onSurface: Colors.white,
      ),
      scaffoldBackgroundColor: darkGrey,
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
        statusBarIconBrightness: brightness == Brightness.dark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: brightness == Brightness.dark ? darkGrey : Colors.white,
        systemNavigationBarIconBrightness: brightness == Brightness.dark ? Brightness.light : Brightness.dark,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
      iconTheme: IconThemeData(color: brightness == Brightness.light ? darkGrey : Colors.white),
      titleTextStyle: GoogleFonts.plusJakartaSans(
        color: brightness == Brightness.light ? darkGrey : Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  static NavigationBarThemeData _buildNavBarTheme(Brightness brightness) {
    return NavigationBarThemeData(
      backgroundColor: Colors.transparent,
      indicatorColor: accentIndigo.withValues(alpha: 0.1),
      labelTextStyle: WidgetStateProperty.all(GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  static TextTheme _buildTextTheme(Brightness brightness) {
    final color = brightness == Brightness.light ? darkGrey : Colors.white;
    return TextTheme(
      displayLarge: GoogleFonts.plusJakartaSans(fontSize: 32, fontWeight: FontWeight.bold, color: color),
      headlineLarge: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.bold, color: color),
      headlineMedium: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w700, color: color),
      titleLarge: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w600, color: color),
      bodyLarge: GoogleFonts.plusJakartaSans(fontSize: 16, color: color.withValues(alpha: 0.9)),
      bodyMedium: GoogleFonts.plusJakartaSans(fontSize: 14, color: color.withValues(alpha: 0.7)),
    );
  }
}
