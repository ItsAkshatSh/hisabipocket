import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisabi/core/models/category_model.dart';
import 'package:hisabi/core/services/ai_service.dart';
import 'package:hisabi/features/receipts/providers/receipts_store.dart';
import 'package:hisabi/features/insights/models/insights_models.dart';
import 'package:hisabi/features/settings/providers/settings_provider.dart';
import 'package:hisabi/features/financial_profile/providers/financial_profile_provider.dart';

// Cache for insights data and the receipt count when it was generated
class InsightsCache {
  final InsightsData data;
  final int receiptCount;
  final DateTime generatedAt;
  
  InsightsCache({
    required this.data,
    required this.receiptCount,
    required this.generatedAt,
  });
}

// State provider to cache insights
final _insightsCacheProvider = StateProvider<InsightsCache?>((ref) => null);

final insightsProvider = FutureProvider.autoDispose<InsightsData>((ref) async {
  final receiptsAsync = ref.watch(receiptsStoreProvider);
  final receipts = receiptsAsync.valueOrNull ?? [];
  final settingsAsync = ref.watch(settingsProvider);
  final currency = settingsAsync.valueOrNull?.currency ?? Currency.USD;
  
  // Watch financial profile to refresh when it changes
  final profileAsync = ref.watch(financialProfileProvider);
  
  // Get current receipt count
  final currentReceiptCount = receipts.length;
  
  // Check if we have cached insights and if receipt count matches
  final cachedInsights = ref.read(_insightsCacheProvider);
  final hasNewReceipts = cachedInsights == null || 
      currentReceiptCount > cachedInsights.receiptCount;
  
  // Check if financial profile changed (income update)
  final profile = profileAsync.valueOrNull;
  final currentIncome = profile?.totalMonthlyIncome ?? 0.0;
  final cachedIncome = cachedInsights?.data.estimatedIncome ?? 0.0;
  final incomeChanged = (currentIncome > 0 && currentIncome != cachedIncome);
  
  if (cachedInsights != null && 
      cachedInsights.receiptCount == currentReceiptCount &&
      cachedInsights.data.currency == currency &&
      !incomeChanged) {
    // Return cached insights if receipt count hasn't changed and income hasn't changed
    return cachedInsights.data;
  }
  
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
  
  // Get income from financial profile, or estimate if not set
  final estimatedIncome = profile?.totalMonthlyIncome ??
      (monthlySpending > 0 ? monthlySpending * 1.5 : 0.0);
  
  // Only generate budget plan using AI if new receipt was added (count increased) or income changed
  // If receipt was deleted, we'll use cached budget plan to save credits
  Map<String, dynamic> budgetPlan;
  if (hasNewReceipts || incomeChanged) {
    // New receipt added, generate AI insights
    final aiService = AIService();
    budgetPlan = await aiService.generateBudgetPlan(
      spendingHistory: categorySpending,
      monthlyIncome: estimatedIncome,
      monthsOfData: 1, // Can be improved to calculate actual months
    );
  } else {
    // Receipt deleted or currency changed, use cached budget plan to save AI credits
    // cachedInsights is guaranteed to be non-null here (we'd be in if branch if it was null)
    budgetPlan = cachedInsights.data.budgetPlan;
  }
  
  // Generate insights (non-AI, always regenerated)
  final insights = _generateInsights(
    categorySpending,
    monthlySpending,
    estimatedIncome,
    currentMonthReceipts.length,
  );
  
  final insightsData = InsightsData(
    categorySpending: categorySpending,
    monthlySpending: monthlySpending,
    estimatedIncome: estimatedIncome,
    budgetPlan: budgetPlan,
    insights: insights,
    currency: currency,
  );
  
  // Cache the insights with current receipt count
  ref.read(_insightsCacheProvider.notifier).state = InsightsCache(
    data: insightsData,
    receiptCount: currentReceiptCount,
    generatedAt: DateTime.now(),
  );
  
  return insightsData;
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

