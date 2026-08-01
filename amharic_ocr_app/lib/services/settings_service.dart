import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_constants.dart';
import '../models/ocr_model_option.dart';


class SettingsService {
  static Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  static Future<String> getServerUrl() async {
    final prefs = await _prefs;
    return prefs.getString(AppConstants.prefServerUrl) ?? AppConstants.defaultServerUrl;
  }

  static Future<void> setServerUrl(String url) async {
    final prefs = await _prefs;
    await prefs.setString(AppConstants.prefServerUrl, url);
  }

  static Future<OcrModelOption> getSelectedModel() async {
    final prefs = await _prefs;
    final key = prefs.getString(AppConstants.prefSelectedModel);
    if (key == null) return OcrModelOption.defaultOption;
    return OcrModelOption.byBackendKey(key);
  }

  static Future<void> setSelectedModel(OcrModelOption option) async {
    final prefs = await _prefs;
    await prefs.setString(AppConstants.prefSelectedModel, option.backendKey);
  }

  static Future<bool> getHasSeenOnboarding() async {
    final prefs = await _prefs;
    return prefs.getBool(AppConstants.prefOnboardingSeen) ?? false;
  }

  static Future<void> setHasSeenOnboarding(bool value) async {
    final prefs = await _prefs;
    await prefs.setBool(AppConstants.prefOnboardingSeen, value);
  }

  /// 0 = system, 1 = light, 2 = dark
  static Future<int> getThemeModeIndex() async {
    final prefs = await _prefs;
    return prefs.getInt(AppConstants.prefThemeMode) ?? 0;
  }

  static Future<void> setThemeModeIndex(int index) async {
    final prefs = await _prefs;
    await prefs.setInt(AppConstants.prefThemeMode, index);
  }
}
