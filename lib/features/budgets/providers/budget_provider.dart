import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisabi/core/models/category_model.dart';
import 'package:hisabi/core/storage/storage_service.dart';
import 'package:hisabi/features/budgets/models/budget_model.dart';
import 'package:hisabi/features/receipts/providers/receipts_store.dart';
import 'package:hisabi/features/financial_profile/providers/financial_profile_provider.dart';
import 'package:hisabi/features/financial_profile/models/recurring_payment_model.dart';

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
  final profileAsync = ref.watch(financialProfileProvider);
  
  final budget = budgetAsync.valueOrNull;
  final receipts = receiptsAsync.valueOrNull ?? [];
  final profile = profileAsync.valueOrNull;
  
  if (budget == null) {
    return {};
  }

  final now = DateTime.now();
  final monthStart = DateTime(now.year, now.month, budget.startDay);
  final monthEnd = DateTime(now.year, now.month + 1, budget.startDay).subtract(const Duration(days: 1));
  
  final effectiveEnd = now.isBefore(monthEnd) ? now : monthEnd;

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

  if (profile != null) {
    for (final payment in profile.recurringPayments) {
      final category = CategoryInfo.mapStringToCategory(payment.category);
      final spentSoFar = _calculateActualOccurrencesInMonth(payment, monthStart, effectiveEnd);
      categorySpending[category] = (categorySpending[category] ?? 0.0) + spentSoFar;
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

  final receiptsTotal = filteredReceipts.fold<double>(0.0, (sum, r) => sum + r.total);
  double totalRecurringSpent = 0.0;
  if (profile != null) {
    for (final p in profile.recurringPayments) {
      totalRecurringSpent += _calculateActualOccurrencesInMonth(p, monthStart, effectiveEnd);
    }
  }
  
  final totalSpent = receiptsTotal + totalRecurringSpent;

  statusMap[ExpenseCategory.other] = BudgetStatus(
    budgeted: budget.monthlyTotal - budget.totalCategoryBudgets,
    spent: totalSpent - statusMap.values.fold(0.0, (sum, status) => sum + status.spent),
  );

  return statusMap;
});

final overallBudgetStatusProvider = FutureProvider.autoDispose<BudgetStatus>((ref) async {
  final budgetAsync = ref.watch(budgetProvider);
  final receiptsAsync = ref.watch(receiptsStoreProvider);
  final profileAsync = ref.watch(financialProfileProvider);
  
  final budget = budgetAsync.valueOrNull;
  final receipts = receiptsAsync.valueOrNull ?? [];
  final profile = profileAsync.valueOrNull;
  
  if (budget == null) {
    return BudgetStatus(budgeted: 0, spent: 0);
  }

  final now = DateTime.now();
  final monthStart = DateTime(now.year, now.month, budget.startDay);
  final monthEnd = DateTime(now.year, now.month + 1, budget.startDay).subtract(const Duration(days: 1));
  final effectiveEnd = now.isBefore(monthEnd) ? now : monthEnd;

  final filteredReceipts = receipts.where((r) => 
    r.date.isAfter(monthStart.subtract(const Duration(days: 1))) &&
    r.date.isBefore(monthEnd.add(const Duration(days: 1)))
  ).toList();

  final receiptsTotal = filteredReceipts.fold<double>(0.0, (sum, r) => sum + r.total);
  
  double totalRecurringSpent = 0.0;
  if (profile != null) {
    for (final p in profile.recurringPayments) {
      totalRecurringSpent += _calculateActualOccurrencesInMonth(p, monthStart, effectiveEnd);
    }
  }
  
  final totalSpent = receiptsTotal + totalRecurringSpent;

  return BudgetStatus(
    budgeted: budget.monthlyTotal,
    spent: totalSpent,
  );
});

double _calculateActualOccurrencesInMonth(RecurringPayment payment, DateTime start, DateTime end) {
  int count = 0;
  DateTime current = payment.startDate;

  while (current.isBefore(start)) {
    current = _nextDate(current, payment.frequency);
  }

  while (!current.isAfter(end)) {
    if (!current.isBefore(start)) {
      count++;
    }
    current = _nextDate(current, payment.frequency);
  }

  return count * payment.amount;
}

DateTime _nextDate(DateTime date, PaymentFrequency frequency) {
  switch (frequency) {
    case PaymentFrequency.weekly:
      return date.add(const Duration(days: 7));
    case PaymentFrequency.biWeekly:
      return date.add(const Duration(days: 14));
    case PaymentFrequency.monthly:
      return DateTime(date.year, date.month + 1, date.day);
    case PaymentFrequency.quarterly:
      return DateTime(date.year, date.month + 3, date.day);
    case PaymentFrequency.yearly:
      return DateTime(date.year + 1, date.month, date.day);
  }
}
