import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

final shouldShowWrappedPromptProvider = FutureProvider.autoDispose<bool>((ref) async {
  try {
    final box = await Hive.openBox('app_preferences');
    final lastWrappedView = box.get('last_wrapped_view') as String?;
    
    if (lastWrappedView == null) {
      return true; // Show if never viewed
    }
    
    final lastViewDate = DateTime.tryParse(lastWrappedView);
    if (lastViewDate == null) {
      return true;
    }
    
    // Show if it's been more than 6 days since last view
    final daysSince = DateTime.now().difference(lastViewDate).inDays;
    return daysSince >= 6;
  } catch (e) {
    return true; // Show on error
  }
});

