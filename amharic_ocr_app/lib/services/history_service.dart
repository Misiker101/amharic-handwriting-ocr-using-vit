import 'package:shared_preferences/shared_preferences.dart';

import '../core/constants/app_constants.dart';
import '../models/scan_history_item.dart';

/// Client-side only "archive" of past recognitions so users don't lose a
/// transcript the moment they leave the screen. Stored entirely on-device.
class HistoryService {
  static Future<List<ScanHistoryItem>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(AppConstants.prefHistory) ?? '';
    final items = ScanHistoryItem.decodeList(raw);
    items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return items;
  }

  static Future<void> add(ScanHistoryItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await getHistory();
    current.insert(0, item);
    final trimmed = current.take(AppConstants.maxHistoryItems).toList();
    await prefs.setString(AppConstants.prefHistory, ScanHistoryItem.encodeList(trimmed));
  }

  static Future<void> remove(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await getHistory();
    current.removeWhere((e) => e.id == id);
    await prefs.setString(AppConstants.prefHistory, ScanHistoryItem.encodeList(current));
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.prefHistory);
  }
}
