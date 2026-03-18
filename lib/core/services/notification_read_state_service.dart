import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class NotificationReadStateService {
  static const String _key = 'read_notification_ids_v1';

  static Future<Set<String>> loadReadIds() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null || raw.isEmpty) return <String>{};
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <String>{};
      return decoded.whereType<String>().toSet();
    } catch (_) {
      return <String>{};
    }
  }

  static Future<void> saveReadIds(Set<String> ids) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(ids.toList(growable: false)));
    } catch (_) {}
  }
}

