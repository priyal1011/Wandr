import 'package:flutter/material.dart';
import '../models/app_settings.dart';

mixin SettingsStore on ChangeNotifier {
  AppSettings settings = AppSettings.defaults();
  String currentCurrency = r'$';
  bool hasSeenOnboarding = false;

  void updateSettings(AppSettings newSettings) {
    settings = newSettings;
    currentCurrency = newSettings.currency;
    notifyListeners();
  }
}
