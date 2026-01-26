import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisabi/features/receipts/providers/receipts_store.dart';
import 'package:hisabi/core/models/category_model.dart';

class ExpenseTrend {
  final DateTime date;
  final double amount;
  final ExpenseCategory? category;

  ExpenseTrend({
    required this.date,
    required this.amount,
    this.category,
  });
}

class TrendAnalysis {
  final List<ExpenseTrend> trends;
  final double averageMonthly;
  final double? monthOverMonthChange;
  final double? yearOverYearChange;
  final ExpenseCategory? topCategory;
  final double? topCategorySpending;

  TrendAnalysis({
    required this.trends,
    required this.averageMonthly,
    this.monthOverMonthChange,
    this.yearOverYearChange,
    this.topCategory,
    this.topCategorySpending,
  });
}

final trendsProvider = FutureProvider.autoDispose<TrendAnalysis>((ref) async {
  final receiptsAsync = ref.watch(receiptsStoreProvider);
  final receipts = receiptsAsync.valueOrNull ?? [];

  if (receipts.isEmpty) {
    return TrendAnalysis(
      trends: [],
      averageMonthly: 0.0,
    );
  }

  final now = DateTime.now();
  final trends = <ExpenseTrend>[];
  final monthlyTotals = <DateTime, double>{};
  final categoryTotals = <ExpenseCategory, double>{};

  for (final receipt in receipts) {
    final monthStart = DateTime(receipt.date.year, receipt.date.month, 1);
    monthlyTotals[monthStart] = (monthlyTotals[monthStart] ?? 0.0) + receipt.total;
    
    final category = receipt.primaryCategory ?? receipt.calculatedPrimaryCategory;
    if (category != null) {
      categoryTotals[category] = (categoryTotals[category] ?? 0.0) + receipt.total;
    }

    trends.add(ExpenseTrend(
      date: receipt.date,
      amount: receipt.total,
      category: category,
    ));
  }

  final sortedMonths = monthlyTotals.keys.toList()..sort();
  final averageMonthly = monthlyTotals.values.isEmpty
      ? 0.0
      : monthlyTotals.values.reduce((a, b) => a + b) / monthlyTotals.length;

  double? monthOverMonthChange;
  if (sortedMonths.length >= 2) {
    final lastMonth = sortedMonths[sortedMonths.length - 1];
    final previousMonth = sortedMonths[sortedMonths.length - 2];
    final lastAmount = monthlyTotals[lastMonth] ?? 0.0;
    final previousAmount = monthlyTotals[previousMonth] ?? 0.0;
    if (previousAmount > 0) {
      monthOverMonthChange = ((lastAmount - previousAmount) / previousAmount) * 100;
    }
  }

  double? yearOverYearChange;
  final currentYear = DateTime(now.year, now.month, 1);
  final lastYear = DateTime(now.year - 1, now.month, 1);
  final currentYearAmount = monthlyTotals[currentYear] ?? 0.0;
  final lastYearAmount = monthlyTotals[lastYear] ?? 0.0;
  if (lastYearAmount > 0) {
    yearOverYearChange = ((currentYearAmount - lastYearAmount) / lastYearAmount) * 100;
  }

  ExpenseCategory? topCategory;
  double? topCategorySpending;
  if (categoryTotals.isNotEmpty) {
    final topEntry = categoryTotals.entries.reduce((a, b) => a.value > b.value ? a : b);
    topCategory = topEntry.key;
    topCategorySpending = topEntry.value;
  }

  return TrendAnalysis(
    trends: trends,
    averageMonthly: averageMonthly,
    monthOverMonthChange: monthOverMonthChange,
    yearOverYearChange: yearOverYearChange,
    topCategory: topCategory,
    topCategorySpending: topCategorySpending,
  );
});

