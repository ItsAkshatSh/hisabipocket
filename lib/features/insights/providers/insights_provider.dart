import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisabi/core/models/category_model.dart';
import 'package:hisabi/core/services/ai_service.dart';
import 'package:hisabi/features/receipts/providers/receipts_store.dart';
import 'package:hisabi/features/insights/models/insights_models.dart';
import 'package:hisabi/features/settings/providers/settings_provider.dart';
import 'package:hisabi/features/financial_profile/providers/financial_profile_provider.dart';
import 'package:hisabi/features/financial_profile/models/recurring_payment_model.dart';

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
  final profile = profileAsync.valueOrNull;
  
  // Get current receipt count
  final currentReceiptCount = receipts.length;
  
  // Check if we have cached insights and if receipt count matches
  final cachedInsights = ref.read(_insightsCacheProvider);
  final hasNewReceipts = cachedInsights == null || 
      currentReceiptCount > cachedInsights.receiptCount;
  
  // Check if financial profile changed (income or recurring payments update)
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
  
  // 1. Add spending from receipts
  for (final receipt in receipts) {
    // Map existing receipt category to the new simplified system
    final mappedCategory = CategoryInfo.mapStringToCategory(
      receipt.primaryCategory?.name ?? receipt.store
    );

    if (receipt.items.isEmpty) {
      categorySpending[mappedCategory] = (categorySpending[mappedCategory] ?? 0.0) + receipt.total;
    } else {
      double itemsTotal = 0.0;
      for (final item in receipt.items) {
        final itemCategory = CategoryInfo.mapStringToCategory(item.category?.name ?? item.name);
        categorySpending[itemCategory] = (categorySpending[itemCategory] ?? 0.0) + item.total;
        itemsTotal += item.total;
      }
      if ((receipt.total - itemsTotal).abs() > 0.01) {
        final diff = receipt.total - itemsTotal;
        categorySpending[mappedCategory] = (categorySpending[mappedCategory] ?? 0.0) + diff;
      }
    }
  }

  // 2. Add spending from recurring payments (normalized to monthly)
  if (profile != null) {
    for (final payment in profile.recurringPayments) {
      double monthlyAmount = 0.0;
      switch (payment.frequency) {
        case PaymentFrequency.weekly:
          monthlyAmount = payment.amount * 4.33;
          break;
        case PaymentFrequency.biWeekly:
          monthlyAmount = payment.amount * 2.17;
          break;
        case PaymentFrequency.monthly:
          monthlyAmount = payment.amount;
          break;
        case PaymentFrequency.quarterly:
          monthlyAmount = payment.amount / 3;
          break;
        case PaymentFrequency.yearly:
          monthlyAmount = payment.amount / 12;
          break;
      }

      final category = CategoryInfo.mapStringToCategory(payment.category ?? payment.name);
      categorySpending[category] = (categorySpending[category] ?? 0.0) + monthlyAmount;
    }
  }
  
  final now = DateTime.now();
  final currentMonthReceipts = receipts.where((r) =>
    r.date.year == now.year && r.date.month == now.month
  ).toList();
  
  final receiptsSpending = currentMonthReceipts.fold<double>(
    0.0,
    (sum, r) => sum + r.total,
  );

  final recurringSpending = profile?.totalMonthlyRecurringPayments ?? 0.0;
  final totalMonthlySpending = receiptsSpending + recurringSpending;
  
  final estimatedIncome = profile?.totalMonthlyIncome ??
      (totalMonthlySpending > 0 ? totalMonthlySpending * 1.5 : 0.0);
  
  // Prepare recurring expenses for AI
  final List<Map<String, dynamic>> recurringExpensesJson = profile?.recurringPayments.map((p) => {
    'name': p.name,
    'amount': p.amount,
    'frequency': p.frequency.name,
    'category': p.category ?? 'Other',
  }).toList() ?? [];

  Map<String, dynamic> budgetPlan;
  if (hasNewReceipts || incomeChanged) {
    final aiService = AIService();
    budgetPlan = await aiService.generateBudgetPlan(
      spendingHistory: categorySpending,
      monthlyIncome: estimatedIncome,
      monthsOfData: 1,
      currencyCode: currency.name,
      recurringExpenses: recurringExpensesJson,
    );
  } else {
    budgetPlan = cachedInsights.data.budgetPlan;
  }
  
  final insights = _generateInsights(
    categorySpending,
    totalMonthlySpending,
    estimatedIncome,
    currentMonthReceipts.length,
  );
  
  final insightsData = InsightsData(
    categorySpending: categorySpending,
    monthlySpending: totalMonthlySpending,
    estimatedIncome: estimatedIncome,
    budgetPlan: budgetPlan,
    insights: insights,
    currency: currency,
  );
  
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
  
  if (receiptsCount > 30) {
    insights.add(
      'You\'ve made $receiptsCount purchases this month. '
      'Consider reviewing subscriptions and recurring expenses.',
    );
  }
  
  return insights;
}
