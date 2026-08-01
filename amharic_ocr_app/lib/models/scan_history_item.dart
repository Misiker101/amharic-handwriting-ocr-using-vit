import 'dart:convert';

/// A locally-persisted record of a completed recognition, purely a
/// client-side convenience feature (nothing is sent to / expected from
/// the backend). Stored as a JSON list in SharedPreferences.
class ScanHistoryItem {
  final String id;
  final DateTime timestamp;
  final String text;
  final String modelLabel;
  final String? visualizationPath;

  ScanHistoryItem({
    required this.id,
    required this.timestamp,
    required this.text,
    required this.modelLabel,
    this.visualizationPath,
  });

  int get wordCount =>
      text.trim().isEmpty ? 0 : text.trim().split(RegExp(r'\s+')).length;

  int get lineCount =>
      text.trim().isEmpty ? 0 : text.trim().split('\n').length;

  Map<String, dynamic> toJson() => {
    'id': id,
    'timestamp': timestamp.toIso8601String(),
    'text': text,
    'modelLabel': modelLabel,
    'visualizationPath': visualizationPath,
  };

  factory ScanHistoryItem.fromJson(Map<String, dynamic> json) {
    return ScanHistoryItem(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      text: json['text'] as String,
      modelLabel: json['modelLabel'] as String? ?? 'Unknown model',
      visualizationPath: json['visualizationPath'] as String?,
    );
  }

  static String encodeList(List<ScanHistoryItem> items) =>
      jsonEncode(items.map((e) => e.toJson()).toList());

  static List<ScanHistoryItem> decodeList(String raw) {
    if (raw.isEmpty) return [];
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => ScanHistoryItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
