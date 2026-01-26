import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisabi/core/storage/storage_service.dart';
import 'package:hisabi/core/widgets/widget_summary.dart';

final savingsGoalsProvider = StateNotifierProvider<SavingsGoalsNotifier, AsyncValue<List<SavingsGoal>>>((ref) {
  final notifier = SavingsGoalsNotifier();
  notifier.loadGoals();
  return notifier;
});

class SavingsGoalsNotifier extends StateNotifier<AsyncValue<List<SavingsGoal>>> {
  SavingsGoalsNotifier() : super(const AsyncValue.data([]));

  Future<void> loadGoals() async {
    state = const AsyncValue.loading();
    try {
      final goals = await StorageService.loadSavingsGoals();
      state = AsyncValue.data(goals);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> addGoal(SavingsGoal goal) async {
    try {
      final current = state.valueOrNull ?? [];
      final updated = [...current, goal];
      await StorageService.saveSavingsGoals(updated);
      state = AsyncValue.data(updated);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> updateGoal(SavingsGoal goal) async {
    try {
      final current = state.valueOrNull ?? [];
      final updated = current.map((g) => 
        g.title == goal.title ? goal : g
      ).toList();
      await StorageService.saveSavingsGoals(updated);
      state = AsyncValue.data(updated);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> deleteGoal(String goalTitle) async {
    try {
      final current = state.valueOrNull ?? [];
      final updated = current.where((g) => g.title != goalTitle).toList();
      await StorageService.saveSavingsGoals(updated);
      state = AsyncValue.data(updated);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> updateGoalProgress(String goalTitle, double amount) async {
    try {
      final current = state.valueOrNull ?? [];
      final updated = current.map((g) => 
        g.title == goalTitle 
          ? SavingsGoal(
              title: g.title,
              targetAmount: g.targetAmount,
              currentAmount: amount,
              targetDate: g.targetDate,
            )
          : g
      ).toList();
      await StorageService.saveSavingsGoals(updated);
      state = AsyncValue.data(updated);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

