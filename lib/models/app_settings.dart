class AppSettings {
  bool isDarkMode;
  String currency;
  AppSettings({required this.isDarkMode, required this.currency});

  factory AppSettings.defaults() =>
      AppSettings(isDarkMode: false, currency: r'$');

  Map<String, dynamic> toJson() => {
    'isDarkMode': isDarkMode,
    'currency': currency,
  };
  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
    isDarkMode: json['isDarkMode'] ?? false,
    currency: json['currency'] ?? r'$',
  );
}
