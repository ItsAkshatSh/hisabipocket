import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisabi/core/models/category_model.dart';
import 'package:hisabi/core/storage/storage_service.dart';
import 'package:hisabi/features/budgets/models/budget_model.dart';
import 'package:hisabi/features/receipts/providers/receipts_store.dart';

final budgetProvider = StateNotifierProvider<BudgetNotifier, AsyncValue<Budget?>>((ref) {
  final notifier = BudgetNotifier();
  notifier.loadBudget();
  return notifier;
});

class BudgetNotifier extends StateNotifier<AsyncValue<Budget?>> {
  BudgetNotifier() : super(const AsyncValue.data(null));

  Future<void> loadBudget() async {
    state = const AsyncValue.loading();
    try {
      final budget = await StorageService.loadBudget();
      state = AsyncValue.data(budget);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> setBudget(Budget budget) async {
    try {
      await StorageService.saveBudget(budget);
      state = AsyncValue.data(budget);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> updateMonthlyTotal(double total) async {
    final current = state.valueOrNull;
    if (current != null) {
      await setBudget(current.copyWith(monthlyTotal: total));
    } else {
      await setBudget(Budget(monthlyTotal: total));
    }
  }

  Future<void> setCategoryBudget(ExpenseCategory category, double amount) async {
    final current = state.valueOrNull;
    if (current != null) {
      final updated = Map<ExpenseCategory, double>.from(current.categoryBudgets);
      if (amount > 0) {
        updated[category] = amount;
      } else {
        updated.remove(category);
      }
      await setBudget(current.copyWith(categoryBudgets: updated));
    } else {
      final budgets = <ExpenseCategory, double>{};
      if (amount > 0) {
        budgets[category] = amount;
      }
      await setBudget(Budget(monthlyTotal: 0, categoryBudgets: budgets));
    }
  }

  Future<void> deleteBudget() async {
    try {
      await StorageService.deleteBudget();
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

final budgetStatusProvider = FutureProvider.autoDispose<Map<ExpenseCategory, BudgetStatus>>((ref) async {
  final budgetAsync = ref.watch(budgetProvider);
  final receiptsAsync = ref.watch(receiptsStoreProvider);
  
  final budget = budgetAsync.valueOrNull;
  final receipts = receiptsAsync.valueOrNull ?? [];
  
  if (budget == null) {
    return {};
  }

  final now = DateTime.now();
  final monthStart = DateTime(now.year, now.month, budget.startDay);
  final monthEnd = DateTime(now.year, now.month + 1, budget.startDay).subtract(const Duration(days: 1));
  
  final filteredReceipts = receipts.where((r) => 
    r.date.isAfter(monthStart.subtract(const Duration(days: 1))) &&
    r.date.isBefore(monthEnd.add(const Duration(days: 1)))
  ).toList();

  final categorySpending = <ExpenseCategory, double>{};
  
  for (final receipt in filteredReceipts) {
    for (final item in receipt.items) {
      final category = item.category ?? ExpenseCategory.other;
      categorySpending[category] = (categorySpending[category] ?? 0.0) + item.total;
    }
  }

  final statusMap = <ExpenseCategory, BudgetStatus>{};
  
  for (final entry in budget.categoryBudgets.entries) {
    final spent = categorySpending[entry.key] ?? 0.0;
    statusMap[entry.key] = BudgetStatus(
      budgeted: entry.value,
      spent: spent,
    );
  }

  final totalSpent = filteredReceipts.fold<double>(0.0, (sum, r) => sum + r.total);
  statusMap[ExpenseCategory.other] = BudgetStatus(
    budgeted: budget.monthlyTotal - budget.totalCategoryBudgets,
    spent: totalSpent - categorySpending.values.fold(0.0, (sum, amount) => sum + amount),
  );

  return statusMap;
});

final overallBudgetStatusProvider = FutureProvider.autoDispose<BudgetStatus>((ref) async {
  final budgetAsync = ref.watch(budgetProvider);
  final receiptsAsync = ref.watch(receiptsStoreProvider);
  
  final budget = budgetAsync.valueOrNull;
  final receipts = receiptsAsync.valueOrNull ?? [];
  
  if (budget == null) {
    return BudgetStatus(budgeted: 0, spent: 0);
  }

  final now = DateTime.now();
  final monthStart = DateTime(now.year, now.month, budget.startDay);
  final monthEnd = DateTime(now.year, now.month + 1, budget.startDay).subtract(const Duration(days: 1));
  
  final filteredReceipts = receipts.where((r) => 
    r.date.isAfter(monthStart.subtract(const Duration(days: 1))) &&
    r.date.isBefore(monthEnd.add(const Duration(days: 1)))
  ).toList();

  final totalSpent = filteredReceipts.fold<double>(0.0, (sum, r) => sum + r.total);

  return BudgetStatus(
    budgeted: budget.monthlyTotal,
    spent: totalSpent,
  );
});

