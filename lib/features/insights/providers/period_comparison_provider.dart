import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisabi/core/models/category_model.dart';
import 'package:hisabi/core/models/receipt_model.dart';
import 'package:hisabi/features/receipts/providers/receipts_store.dart';
import 'package:hisabi/features/insights/models/period_comparison.dart';
import 'package:hisabi/features/financial_profile/providers/financial_profile_provider.dart';
import 'package:hisabi/features/financial_profile/models/recurring_payment_model.dart';
import 'package:hisabi/features/financial_profile/models/financial_profile_model.dart';

final periodComparisonProvider = FutureProvider.autoDispose<PeriodComparison?>((ref) async {
  final receiptsAsync = ref.watch(receiptsStoreProvider);
  final profileAsync = ref.watch(financialProfileProvider);
  
  final receipts = receiptsAsync.valueOrNull ?? [];
  final profile = profileAsync.valueOrNull;
  
  if (receipts.isEmpty && (profile == null || profile.recurringPayments.isEmpty)) {
    return null;
  }
  
  final now = DateTime.now();
  final monthStart = DateTime(now.year, now.month, 1);
  final effectiveEnd = now;

  final lastMonthDate = DateTime(now.year, now.month - 1, 1);
  final lastMonthStart = lastMonthDate;
  final lastMonthEnd = DateTime(now.year, now.month, 1).subtract(const Duration(days: 1));
  
  // Helper to calculate category totals for a specific window
  Map<ExpenseCategory, double> calculateTotals(DateTime start, DateTime end, List<ReceiptModel> allReceipts, FinancialProfile? profile) {
    final totals = <ExpenseCategory, double>{};
    
    // Initialize all with 0
    for (var cat in ExpenseCategory.values) {
      totals[cat] = 0.0;
    }

    // 1. Add Receipts in window
    final windowReceipts = allReceipts.where((r) => 
      r.date.isAfter(start.subtract(const Duration(days: 1))) &&
      r.date.isBefore(end.add(const Duration(days: 1)))
    ).toList();

    for (final receipt in windowReceipts) {
      final mappedCategory = CategoryInfo.mapStringToCategory(
        receipt.primaryCategory?.name ?? receipt.store
      );
      
      if (receipt.items.isEmpty) {
        totals[mappedCategory] = (totals[mappedCategory] ?? 0.0) + receipt.total;
      } else {
        for (final item in receipt.items) {
          final itemCategory = CategoryInfo.mapStringToCategory(item.category?.name ?? item.name);
          totals[itemCategory] = (totals[itemCategory] ?? 0.0) + item.total;
        }
      }
    }

    // 2. Add Recurring Payments that occurred in window (Pay-As-You-Go)
    if (profile != null) {
      for (final payment in profile.recurringPayments) {
        final amountInWindow = _calculateOccurrencesInWindow(payment, start, end);
        if (amountInWindow > 0) {
          final category = CategoryInfo.mapStringToCategory(payment.category ?? payment.name);
          totals[category] = (totals[category] ?? 0.0) + amountInWindow;
        }
      }
    }
    
    return totals;
  }

  final currentCategorySpending = calculateTotals(monthStart, effectiveEnd, receipts, profile);
  final previousCategorySpending = calculateTotals(lastMonthStart, lastMonthEnd, receipts, profile);
  
  final currentAmount = currentCategorySpending.values.fold(0.0, (a, b) => a + b);
  final previousAmount = previousCategorySpending.values.fold(0.0, (a, b) => a + b);
  
  if (previousAmount == 0 && currentAmount == 0) return null;

  final change = currentAmount - previousAmount;
  final changePercent = previousAmount > 0 ? (change / previousAmount) * 100 : 0.0;
  
  final categoryComparisons = <ExpenseCategory, CategoryComparison>{};
  final insights = <String>[];
  
  for (final category in ExpenseCategory.values) {
    final current = currentCategorySpending[category] ?? 0.0;
    final previous = previousCategorySpending[category] ?? 0.0;
    
    if (current == 0 && previous == 0) continue;

    final change = current - previous;
    final changePercent = previous > 0 ? (change / previous) * 100 : 0.0;
    final isSignificant = changePercent.abs() > 20;
    
    String insight;
    if (previous == 0 && current > 0) {
      insight = 'New category spending: ${CategoryInfo.getInfo(category).name}';
    } else if (current == 0 && previous > 0) {
      insight = 'No spending in ${CategoryInfo.getInfo(category).name} this month';
    } else if (changePercent > 0) {
      insight = '${CategoryInfo.getInfo(category).name} increased by ${changePercent.toStringAsFixed(0)}%';
    } else {
      insight = '${CategoryInfo.getInfo(category).name} decreased by ${changePercent.abs().toStringAsFixed(0)}%';
    }
    
    if (isSignificant) insights.add(insight);
    
    categoryComparisons[category] = CategoryComparison(
      category: category,
      current: current,
      previous: previous,
      change: change,
      changePercent: changePercent,
      insight: insight,
      isSignificant: isSignificant,
    );
  }
  
  return PeriodComparison(
    currentAmount: currentAmount,
    previousAmount: previousAmount,
    changePercent: changePercent,
    trend: changePercent > 5 ? 'up' : (changePercent < -5 ? 'down' : 'stable'),
    periodType: PeriodType.month,
    categoryComparisons: categoryComparisons,
    insights: insights,
  );
});

double _calculateOccurrencesInWindow(RecurringPayment payment, DateTime start, DateTime end) {
  int count = 0;
  DateTime current = payment.startDate;

  DateTime nextDate(DateTime d, PaymentFrequency freq) {
    switch (freq) {
      case PaymentFrequency.weekly: return d.add(const Duration(days: 7));
      case PaymentFrequency.biWeekly: return d.add(const Duration(days: 14));
      case PaymentFrequency.monthly: return DateTime(d.year, d.month + 1, d.day);
      case PaymentFrequency.quarterly: return DateTime(d.year, d.month + 3, d.day);
      case PaymentFrequency.yearly: return DateTime(d.year + 1, d.month, d.day);
    }
  }

  // Move forward to the first occurrence after or on 'start'
  while (current.isBefore(start)) {
    current = nextDate(current, payment.frequency);
  }

  // Count how many times it hits within the [start, end] window
  while (!current.isAfter(end)) {
    if (!current.isBefore(start)) {
      count++;
    }
    current = nextDate(current, payment.frequency);
  }

  return count * payment.amount;
}
