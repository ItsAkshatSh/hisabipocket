import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisabi/core/models/category_model.dart';
import 'package:hisabi/core/models/receipt_model.dart';
import 'package:hisabi/features/receipts/providers/receipts_store.dart';
import 'package:hisabi/features/insights/models/period_comparison.dart';
import 'package:hisabi/features/financial_profile/providers/financial_profile_provider.dart';
import 'package:hisabi/features/financial_profile/models/recurring_payment_model.dart';

final periodComparisonProvider = FutureProvider.autoDispose<PeriodComparison?>((ref) async {
  final receiptsAsync = ref.watch(receiptsStoreProvider);
  final profileAsync = ref.watch(financialProfileProvider);
  
  final receipts = receiptsAsync.valueOrNull ?? [];
  final profile = profileAsync.valueOrNull;
  
  if (receipts.isEmpty && (profile == null || profile.recurringPayments.isEmpty)) {
    return null;
  }
  
  final now = DateTime.now();
  
  // 1. Get current month data
  final currentMonthReceipts = receipts.where((r) =>
    r.date.year == now.year && r.date.month == now.month
  ).toList();
  
  // 2. Get last month data
  final lastMonthDate = DateTime(now.year, now.month - 1);
  final lastMonthReceipts = receipts.where((r) =>
    r.date.year == lastMonthDate.year && r.date.month == lastMonthDate.month
  ).toList();
  
  // Helper to calculate category totals
  Map<ExpenseCategory, double> calculateTotals(List<ReceiptModel> monthReceipts) {
    final totals = <ExpenseCategory, double>{};
    
    // Initialize all with 0
    for (var cat in ExpenseCategory.values) {
      totals[cat] = 0.0;
    }

    // Add Receipts
    for (final receipt in monthReceipts) {
      final mappedCategory = CategoryInfo.mapStringToCategory(
        receipt.primaryCategory?.name ?? receipt.store
      );
      
      if (receipt.items.isEmpty) {
        totals[mappedCategory] = (totals[mappedCategory] ?? 0.0) + receipt.total;
      } else {
        double itemsTotal = 0.0;
        for (final item in receipt.items) {
          final itemCategory = CategoryInfo.mapStringToCategory(item.category?.name ?? item.name);
          totals[itemCategory] = (totals[itemCategory] ?? 0.0) + item.total;
          itemsTotal += item.total;
        }
        if ((receipt.total - itemsTotal).abs() > 0.01) {
          totals[mappedCategory] = (totals[mappedCategory] ?? 0.0) + (receipt.total - itemsTotal);
        }
      }
    }

    // Add Normalized Recurring Payments (always assume they apply to every month)
    if (profile != null) {
      for (final payment in profile.recurringPayments) {
        double monthlyAmount = 0.0;
        switch (payment.frequency) {
          case PaymentFrequency.weekly: monthlyAmount = payment.amount * 4.33; break;
          case PaymentFrequency.biWeekly: monthlyAmount = payment.amount * 2.17; break;
          case PaymentFrequency.monthly: monthlyAmount = payment.amount; break;
          case PaymentFrequency.quarterly: monthlyAmount = payment.amount / 3; break;
          case PaymentFrequency.yearly: monthlyAmount = payment.amount / 12; break;
        }
        final category = CategoryInfo.mapStringToCategory(payment.category ?? payment.name);
        totals[category] = (totals[category] ?? 0.0) + monthlyAmount;
      }
    }
    
    return totals;
  }

  final currentCategorySpending = calculateTotals(currentMonthReceipts);
  final previousCategorySpending = calculateTotals(lastMonthReceipts);
  
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
    
    // Skip categories with no activity in either month to keep UI clean
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
