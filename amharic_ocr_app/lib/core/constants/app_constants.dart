class AppConstants {
  AppConstants._();

  /// Default backend base URL. This is only a *default* now — it is
  /// editable at runtime from the Settings screen and persisted locally,
  /// so longer need to hardcode + rebuild the app every time the
  /// PC's IP changes on the Wi-Fi network.
  static const String defaultServerUrl = "http://192.168.137.1:8000";

  static const String segmentEndpoint = "/segment";
  static String recognizeEndpoint(String sessionId) => "/recognize/$sessionId";

  // SharedPreferences keys
  static const String prefServerUrl = "pref_server_url";
  static const String prefSelectedModel = "pref_selected_model";
  static const String prefHistory = "pref_scan_history";
  static const String prefOnboardingSeen = "pref_onboarding_seen";
  static const String prefThemeMode = "pref_theme_mode";

  static const int maxHistoryItems = 50;
}
