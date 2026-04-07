import 'package:flutter/material.dart';

class AppSnackbar {
  static void success(BuildContext context, String message) {
    _show(context, message, Colors.green.shade700);
  }

  static void error(BuildContext context, String message) {
    _show(context, message, Colors.red.shade700);
  }

  static void info(BuildContext context, String message) {
    _show(context, message, const Color(0xFF1E293B)); // Navy
  }

  static void _show(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
