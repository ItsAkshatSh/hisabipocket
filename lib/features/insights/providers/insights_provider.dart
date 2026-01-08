import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisabi/core/models/receipt_model.dart';
import 'package:hisabi/core/models/category_model.dart';
import 'package:hisabi/core/services/ai_service.dart';
import 'package:hisabi/features/receipts/providers/receipts_store.dart';
import 'package:hisabi/features/insights/models/insights_models.dart';
import 'package:hisabi/features/settings/providers/settings_provider.dart';

final insightsProvider = FutureProvider.autoDispose<InsightsData>((ref) async {
  final receiptsAsync = ref.watch(receiptsStoreProvider);
  final receipts = receiptsAsync.valueOrNull ?? [];
  final settingsAsync = ref.watch(settingsProvider);
  final currency = settingsAsync.valueOrNull?.currency ?? Currency.USD;
  
  // Calculate spending by category
  final categorySpending = <ExpenseCategory, double>{};
  for (final receipt in receipts) {
    for (final item in receipt.items) {
      final category = item.category ?? ExpenseCategory.other;
      categorySpending[category] = (categorySpending[category] ?? 0.0) + item.total;
    }
  }
  
  // Get current month spending
  final now = DateTime.now();
  final currentMonthReceipts = receipts.where((r) =>
    r.date.year == now.year && r.date.month == now.month
  ).toList();
  
  final monthlySpending = currentMonthReceipts.fold<double>(
    0.0,
    (sum, r) => sum + r.total,
  );
  
  // Estimate monthly income (can be improved with user input)
  final estimatedIncome = monthlySpending * 1.5; // Assume spending is 66% of income
  
  // Generate budget plan using AI
  final aiService = AIService();
  final budgetPlan = await aiService.generateBudgetPlan(
    spendingHistory: categorySpending,
    monthlyIncome: estimatedIncome,
    monthsOfData: 1, // Can be improved to calculate actual months
  );
  
  // Generate insights
  final insights = _generateInsights(
    categorySpending,
    monthlySpending,
    estimatedIncome,
    currentMonthReceipts.length,
  );
  
  return InsightsData(
    categorySpending: categorySpending,
    monthlySpending: monthlySpending,
    estimatedIncome: estimatedIncome,
    budgetPlan: budgetPlan,
    insights: insights,
    currency: currency,
  );
});

List<String> _generateInsights(
  Map<ExpenseCategory, double> categorySpending,
  double monthlySpending,
  double estimatedIncome,
  int receiptsCount,
) {
  final insights = <String>[];
  
  // Find top spending category
  if (categorySpending.isNotEmpty) {
    final topCategory = categorySpending.entries.reduce(
      (a, b) => a.value > b.value ? a : b,
    );
    final categoryInfo = CategoryInfo.getInfo(topCategory.key);
    insights.add(
      'Your top spending category is ${categoryInfo.name} (${categoryInfo.emoji}) - '
      'consider setting a budget limit for this category.',
    );
  }
  
  // Savings rate
  final savingsRate = estimatedIncome > 0
      ? ((estimatedIncome - monthlySpending) / estimatedIncome * 100)
      : 0;
  if (savingsRate < 20) {
    insights.add(
      'Your savings rate is ${savingsRate.toStringAsFixed(1)}%. '
      'Aim for at least 20% to build a strong financial foundation.',
    );
  } else {
    insights.add(
      'Great job! Your savings rate is ${savingsRate.toStringAsFixed(1)}%. '
      'Keep up the excellent financial habits!',
    );
  }
  
  // Receipt frequency
  if (receiptsCount > 30) {
    insights.add(
      'You\'ve made $receiptsCount purchases this month. '
      'Consider reviewing subscriptions and recurring expenses.',
    );
  }
  
  return insights;
}

