import 'package:flutter/services.dart';

/// A centralized utility for managing tactile UX across Wandr.
/// Uses Flutter's system haptics to provide a premium, physical feel.
class HapticHelper {
  /// Light tap for subtle interactions like grid snapping or selection.
  static Future<void> light() async {
    await HapticFeedback.lightImpact();
  }

  /// Medium impact for primary actions like button presses.
  static Future<void> medium() async {
    await HapticFeedback.mediumImpact();
  }

  /// Heavy impact for significant events like successful saves.
  static Future<void> heavy() async {
    await HapticFeedback.heavyImpact();
  }

  /// Specialized double-pulse for successful operations (e.g. Saved Memory).
  static Future<void> success() async {
    await HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 50));
    await HapticFeedback.lightImpact();
  }

  /// Specialized stutter for errors or validation alerts.
  static Future<void> error() async {
    await HapticFeedback.vibrate();
  }

  /// Subtle click for navigating tabs or toggling simple switches.
  static Future<void> selection() async {
    await HapticFeedback.selectionClick();
  }
}
