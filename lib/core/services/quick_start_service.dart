import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

class QuickStartService {
  static const String _key = 'has_completed_quick_start_v1';

  static bool? _memoryCache;
  static String? _memoryScope;

  static String _scopedKey() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return uid == null ? _key : '${_key}_$uid';
  }

  static Future<bool> hasCompletedQuickStart() async {
    final scope = FirebaseAuth.instance.currentUser?.uid;
    if (_memoryScope != scope) {
      _memoryScope = scope;
      _memoryCache = null;
    }

    if (_memoryCache != null) return _memoryCache!;

    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getBool(_scopedKey()) ?? false;
      _memoryCache = value;
      return value;
    } catch (_) {
      return _memoryCache ?? false;
    }
  }

  static Future<void> setCompletedQuickStart() async {
    _memoryCache = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_scopedKey(), true);
    } catch (_) {}
  }

  static Future<void> resetQuickStart() async {
    _memoryCache = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_scopedKey());
    } catch (_) {}
  }
}

