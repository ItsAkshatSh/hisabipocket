import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hisabi/features/receipts/providers/receipts_store.dart';

DateTime _getWeekSunday(DateTime date) {
  // ISO 8601: 1 is Monday, 7 is Sunday.
  final daysToSubtract = date.weekday == 7 ? 0 : date.weekday;
  final sunday = date.subtract(Duration(days: daysToSubtract));
  return DateTime(sunday.year, sunday.month, sunday.day);
}

String _getWeekIdentifier(DateTime date) {
  final sunday = _getWeekSunday(date);
  return 'wrapped_${sunday.year}_${sunday.month}_${sunday.day}';
}

final shouldShowWrappedPromptProvider = FutureProvider.autoDispose<bool>((ref) async {
  // Watch receipts to ensure we re-evaluate when data arrives
  final receiptsAsync = ref.watch(receiptsStoreProvider);
  
  try {
    final now = DateTime.now();
    print('Checking Weekly Wrapped: Day ${now.weekday}');
    
    // 1. Check if today is Sunday (7) or even very early Monday (1) 
    // to account for different timezones/late nights
    final isSunday = now.weekday == 7;
    if (!isSunday) {
      print('Not Sunday, hiding wrap.');
      return false;
    }
    
    // 2. Check if there are receipts at all. 
    // We want to make sure the data is actually loaded.
    if (receiptsAsync is AsyncLoading) return false;
    final receipts = receiptsAsync.valueOrNull ?? [];
    
    if (receipts.isEmpty) {
      print('No receipts found, hiding wrap.');
      return false;
    }
    
    // 3. Check if already viewed this week using SharedPreferences (more reliable)
    final currentWeekId = _getWeekIdentifier(now);
    final prefs = await SharedPreferences.getInstance();
    final lastViewedWeekId = prefs.getString('last_wrapped_week_id');
    
    print('Current Week ID: $currentWeekId, Last Viewed: $lastViewedWeekId');
    
    final shouldShow = lastViewedWeekId != currentWeekId;
    print('Should show banner: $shouldShow');
    
    return shouldShow;
  } catch (e) {
    print('Error in wrapped prompt provider: $e');
    return false;
  }
});
