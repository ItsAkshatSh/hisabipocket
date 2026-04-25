import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OnboardingService {
  static const String _localKey = 'has_seen_onboarding_v1';
  
  static bool? _memoryCache;
  static String? _memoryScope;

  static String _scopedKey() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return uid == null ? _localKey : '${_localKey}_$uid';
  }

  /// Check if the user has already seen the onboarding
  static Future<bool> hasSeenOnboarding() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    final scope = user.uid;
    if (_memoryScope != scope) {
      _memoryScope = scope;
      _memoryCache = null;
    }

    if (_memoryCache != null) return _memoryCache!;
    
    // 1. Try local storage first (fastest)
    try {
      final prefs = await SharedPreferences.getInstance();
      final localValue = prefs.getBool(_scopedKey());
      if (localValue == true) {
        _memoryCache = true;
        return true;
      }
    } catch (_) {}

    // 2. Check Firebase if not found locally (survives reinstalls)
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      if (doc.exists && doc.data() != null) {
        final remoteValue = doc.data()!['hasSeenOnboarding'] as bool?;
        if (remoteValue == true) {
          // Sync to local for next time
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool(_scopedKey(), true);
          _memoryCache = true;
          return true;
        }
      }
    } catch (e) {
      print('Error fetching onboarding status from Firebase: $e');
    }

    return false;
  }

  /// Mark onboarding as seen
  static Future<void> setSeenOnboarding() async {
    _memoryCache = true;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // 1. Save locally
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_scopedKey(), true);
    } catch (_) {}

    // 2. Sync to Firebase
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .set({
            'hasSeenOnboarding': true,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } catch (e) {
      print('Error saving onboarding status to Firebase: $e');
    }
  }

  /// Reset onboarding
  static Future<void> resetOnboarding() async {
    _memoryCache = false;
    final user = FirebaseAuth.instance.currentUser;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_scopedKey());
    } catch (_) {}

    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'hasSeenOnboarding': false});
      } catch (_) {}
    }
  }
}
