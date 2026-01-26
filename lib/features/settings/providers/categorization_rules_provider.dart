import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisabi/core/storage/storage_service.dart';
import 'package:hisabi/features/settings/models/categorization_rule_model.dart';

final categorizationRulesProvider = StateNotifierProvider<CategorizationRulesNotifier, AsyncValue<List<CategorizationRule>>>((ref) {
  final notifier = CategorizationRulesNotifier();
  notifier.loadRules();
  return notifier;
});

class CategorizationRulesNotifier extends StateNotifier<AsyncValue<List<CategorizationRule>>> {
  CategorizationRulesNotifier() : super(const AsyncValue.data([]));

  Future<void> loadRules() async {
    state = const AsyncValue.loading();
    try {
      final rules = await StorageService.loadCategorizationRules();
      state = AsyncValue.data(rules);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> addRule(CategorizationRule rule) async {
    try {
      final current = state.valueOrNull ?? [];
      final updated = [...current, rule];
      await StorageService.saveCategorizationRules(updated);
      state = AsyncValue.data(updated);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> updateRule(CategorizationRule rule) async {
    try {
      final current = state.valueOrNull ?? [];
      final updated = current.map((r) => r.id == rule.id ? rule : r).toList();
      await StorageService.saveCategorizationRules(updated);
      state = AsyncValue.data(updated);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> deleteRule(String ruleId) async {
    try {
      final current = state.valueOrNull ?? [];
      final updated = current.where((r) => r.id != ruleId).toList();
      await StorageService.saveCategorizationRules(updated);
      state = AsyncValue.data(updated);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> toggleRule(String ruleId) async {
    try {
      final current = state.valueOrNull ?? [];
      final updated = current.map((r) => 
        r.id == ruleId ? r.copyWith(isActive: !r.isActive) : r
      ).toList();
      await StorageService.saveCategorizationRules(updated);
      state = AsyncValue.data(updated);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

