import 'package:shared_preferences/shared_preferences.dart';

class OnboardingService {
  static const String _key = 'has_seen_onboarding_v1';
  
  // Fallback in-memory cache if SharedPreferences fails
  static bool? _memoryCache;

  /// Check if the user has already seen the onboarding
  static Future<bool> hasSeenOnboarding() async {
    // Check memory cache first
    if (_memoryCache != null) {
      return _memoryCache!;
    }
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final value = prefs.getBool(_key) ?? false;
      // Update memory cache
      _memoryCache = value;
      return value;
    } catch (e) {
      // If SharedPreferences fails, check memory cache
      if (_memoryCache != null) {
        return _memoryCache!;
      }
      // If there's an error and no cache, assume they haven't seen it
      // This ensures first-time users still see onboarding even if storage fails
      return false;
    }
  }

  /// Mark onboarding as seen
  static Future<void> setSeenOnboarding() async {
    // Update memory cache immediately
    _memoryCache = true;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, true);
    } catch (e) {
      // If SharedPreferences fails, we still have the memory cache
      // This is acceptable for the session, but won't persist across app restarts
      // The error is expected if the app needs a rebuild after adding the dependency
      if (e.toString().contains('channel-error') || 
          e.toString().contains('PlatformException')) {
        // This usually means the app needs a full rebuild (not just hot reload)
        // The memory cache will handle it for this session
        return;
      }
      // For other errors, still log but don't fail
      print('Warning: Could not persist onboarding status: $e');
    }
  }

  /// Reset onboarding (useful for testing or if user wants to see it again)
  static Future<void> resetOnboarding() async {
    // Clear memory cache
    _memoryCache = false;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (e) {
      // If SharedPreferences fails, memory cache is already cleared
      print('Warning: Could not reset onboarding status: $e');
    }
  }
}

