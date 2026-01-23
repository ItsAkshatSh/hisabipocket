import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

DateTime _getWeekSunday(DateTime date) {
  final daysToSubtract = date.weekday == 7 ? 0 : date.weekday;
  final sunday = date.subtract(Duration(days: daysToSubtract));
  return DateTime(sunday.year, sunday.month, sunday.day);
}

String _getWeekIdentifier(DateTime date) {
  final sunday = _getWeekSunday(date);
  return '${sunday.year}-${sunday.month.toString().padLeft(2, '0')}-${sunday.day.toString().padLeft(2, '0')}';
}

final shouldShowWrappedPromptProvider = FutureProvider.autoDispose<bool>((ref) async {
  try {
    final now = DateTime.now();
    
    if (now.weekday != 7) {
      return false;
    }
    
    final currentWeekId = _getWeekIdentifier(now);
    
    final box = await Hive.openBox('app_preferences');
    final lastViewedWeekId = box.get('last_wrapped_week_id') as String?;
    
    return lastViewedWeekId != currentWeekId;
  } catch (e) {
    return false;
  }
});

