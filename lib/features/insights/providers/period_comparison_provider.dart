import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisabi/core/models/receipt_model.dart';
import 'package:hisabi/core/models/category_model.dart';
import 'package:hisabi/features/receipts/providers/receipts_store.dart';
import 'package:hisabi/features/insights/models/period_comparison.dart';

final periodComparisonProvider = FutureProvider.autoDispose<PeriodComparison?>((ref) async {
  final receiptsAsync = ref.watch(receiptsStoreProvider);
  final receipts = receiptsAsync.valueOrNull ?? [];
  
  if (receipts.length < 2) {
    return null; // Need at least some data
  }
  
  final now = DateTime.now();
  
  // Get current month receipts
  final currentMonthReceipts = receipts.where((r) =>
    r.date.year == now.year && r.date.month == now.month
  ).toList();
  
  // Get last month receipts
  final lastMonth = now.subtract(const Duration(days: 30));
  final lastMonthReceipts = receipts.where((r) =>
    r.date.year == lastMonth.year && r.date.month == lastMonth.month
  ).toList();
  
  if (lastMonthReceipts.isEmpty) {
    return null; // No data to compare
  }
  
  // Calculate current month spending
  final currentAmount = currentMonthReceipts.fold<double>(
    0.0,
    (sum, r) => sum + r.total,
  );
  
  // Calculate last month spending
  final previousAmount = lastMonthReceipts.fold<double>(
    0.0,
    (sum, r) => sum + r.total,
  );
  
  // Calculate change
  final change = currentAmount - previousAmount;
  final changePercent = previousAmount > 0
      ? (change / previousAmount) * 100
      : 0.0;
  
  // Determine trend
  String trend;
  if (changePercent > 5) {
    trend = 'up';
  } else if (changePercent < -5) {
    trend = 'down';
  } else {
    trend = 'stable';
  }
  
  // Calculate category comparisons
  final currentCategorySpending = <ExpenseCategory, double>{};
  for (final receipt in currentMonthReceipts) {
    for (final item in receipt.items) {
      final category = item.category ?? ExpenseCategory.other;
      currentCategorySpending[category] = (currentCategorySpending[category] ?? 0.0) + item.total;
    }
  }
  
  final previousCategorySpending = <ExpenseCategory, double>{};
  for (final receipt in lastMonthReceipts) {
    for (final item in receipt.items) {
      final category = item.category ?? ExpenseCategory.other;
      previousCategorySpending[category] = (previousCategorySpending[category] ?? 0.0) + item.total;
    }
  }
  
  // Get all categories
  final allCategories = <ExpenseCategory>{};
  allCategories.addAll(currentCategorySpending.keys);
  allCategories.addAll(previousCategorySpending.keys);
  
  final categoryComparisons = <ExpenseCategory, CategoryComparison>{};
  final insights = <String>[];
  
  for (final category in allCategories) {
    final current = currentCategorySpending[category] ?? 0.0;
    final previous = previousCategorySpending[category] ?? 0.0;
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
    } else if (changePercent < 0) {
      insight = '${CategoryInfo.getInfo(category).name} decreased by ${changePercent.abs().toStringAsFixed(0)}%';
    } else {
      insight = '${CategoryInfo.getInfo(category).name} spending is stable';
    }
    
    if (isSignificant) {
      insights.add(insight);
    }
    
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
  
  // Generate overall insight
  if (changePercent.abs() > 10) {
    if (changePercent > 0) {
      insights.insert(0, 'You spent ${changePercent.toStringAsFixed(0)}% more this month');
    } else {
      insights.insert(0, 'You spent ${changePercent.abs().toStringAsFixed(0)}% less this month');
    }
  } else {
    insights.insert(0, 'Your spending is relatively stable compared to last month');
  }
  
  return PeriodComparison(
    currentAmount: currentAmount,
    previousAmount: previousAmount,
    changePercent: changePercent,
    trend: trend,
    periodType: PeriodType.month,
    categoryComparisons: categoryComparisons,
    insights: insights,
  );
});
