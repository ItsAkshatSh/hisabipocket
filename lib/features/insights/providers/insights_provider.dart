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
  
  // Check if financial profile changed (income or recurring payments update)
  final currentIncome = profile?.totalMonthlyIncome ?? 0.0;
  final cachedIncome = cachedInsights?.data.estimatedIncome ?? 0.0;
  final incomeChanged = (currentIncome > 0 && currentIncome != cachedIncome);
  
  if (cachedInsights != null && 
      cachedInsights.receiptCount == currentReceiptCount &&
      cachedInsights.data.currency == currency &&
      !incomeChanged) {
    return cachedInsights.data;
  }
  
  final now = DateTime.now();
  final monthStart = DateTime(now.year, now.month, 1);
  final monthEnd = DateTime(now.year, now.month + 1, 1).subtract(const Duration(days: 1));
  final effectiveEnd = now.isBefore(monthEnd) ? now : monthEnd;

  // 1. Calculate current month spending from receipts
  final currentMonthReceipts = receipts.where((r) =>
    r.date.isAfter(monthStart.subtract(const Duration(days: 1))) &&
    r.date.isBefore(monthEnd.add(const Duration(days: 1)))
  ).toList();
  
  final receiptsSpending = currentMonthReceipts.fold<double>(
    0.0,
    (sum, r) => sum + r.total,
  );

  // 2. Calculate current month spending from recurring payments (Pay-As-You-Go logic)
  double recurringSpending = 0.0;
  final categorySpending = <ExpenseCategory, double>{};

  // Pre-fill categories from current month receipts
  for (final receipt in currentMonthReceipts) {
    final mappedCategory = CategoryInfo.mapStringToCategory(
      receipt.primaryCategory?.name ?? receipt.store
    );
    
    if (receipt.items.isEmpty) {
      categorySpending[mappedCategory] = (categorySpending[mappedCategory] ?? 0.0) + receipt.total;
    } else {
      for (final item in receipt.items) {
        final itemCategory = CategoryInfo.mapStringToCategory(item.category?.name ?? item.name);
        categorySpending[itemCategory] = (categorySpending[itemCategory] ?? 0.0) + item.total;
      }
    }
  }

  // Add recurring payments that have occurred so far this month
  if (profile != null) {
    for (final payment in profile.recurringPayments) {
      final amountPaidThisMonth = _calculateOccurrencesInWindow(payment, monthStart, effectiveEnd);
      if (amountPaidThisMonth > 0) {
        recurringSpending += amountPaidThisMonth;
        final category = CategoryInfo.mapStringToCategory(payment.category ?? payment.name);
        categorySpending[category] = (categorySpending[category] ?? 0.0) + amountPaidThisMonth;
      }
    }
  }

  final totalMonthlySpending = receiptsSpending + recurringSpending;
  
  final estimatedIncome = profile?.totalMonthlyIncome ??
      (totalMonthlySpending > 0 ? totalMonthlySpending * 1.5 : 0.0);
  
  // Prepare full spending history for AI budget planning
  final fullCategoryHistory = <ExpenseCategory, double>{};
  for (final receipt in receipts) {
    final cat = CategoryInfo.mapStringToCategory(receipt.primaryCategory?.name ?? receipt.store);
    fullCategoryHistory[cat] = (fullCategoryHistory[cat] ?? 0.0) + receipt.total;
  }

  // Prepare recurring expenses for AI
  final List<Map<String, dynamic>> recurringExpensesJson = profile?.recurringPayments.map((p) => {
    'name': p.name,
    'amount': p.amount,
    'frequency': p.frequency.name,
    'category': p.category ?? 'Other',
  }).toList() ?? [];

  final aiService = AIService();
  final budgetPlan = await aiService.generateBudgetPlan(
    spendingHistory: fullCategoryHistory,
    monthlyIncome: estimatedIncome,
    monthsOfData: 1,
    currencyCode: currency.name,
    recurringExpenses: recurringExpensesJson,
  );
  
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

  while (current.isBefore(start)) {
    current = nextDate(current, payment.frequency);
  }

  while (!current.isAfter(end)) {
    if (!current.isBefore(start)) {
      count++;
    }
    current = nextDate(current, payment.frequency);
  }

  return count * payment.amount;
}

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
