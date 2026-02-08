import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisabi/core/models/category_model.dart';
import 'package:hisabi/core/services/ai_service.dart';
import 'package:hisabi/features/receipts/providers/receipts_store.dart';
import 'package:hisabi/features/insights/models/insights_models.dart';
import 'package:hisabi/features/settings/providers/settings_provider.dart';
import 'package:hisabi/features/financial_profile/providers/financial_profile_provider.dart';
import 'package:hisabi/features/financial_profile/models/recurring_payment_model.dart';
import 'package:hisabi/features/budgets/providers/budget_provider.dart';
import 'package:hisabi/features/budgets/models/budget_model.dart';

// Cache for insights data and the receipt count when it was generated
class InsightsCache {
  final InsightsData data;
  final int receiptCount;
  final double income;
  final DateTime generatedAt;
  
  InsightsCache({
    required this.data,
    required this.receiptCount,
    required this.income,
    required this.generatedAt,
  });
}

// State provider to cache insights - persistent across navigation
final _insightsCacheProvider = StateProvider<InsightsCache?>((ref) => null);

final insightsProvider = FutureProvider.autoDispose<InsightsData>((ref) async {
  final receiptsAsync = ref.watch(receiptsStoreProvider);
  final settingsAsync = ref.watch(settingsProvider);
  final profileAsync = ref.watch(financialProfileProvider);
  
  // 1. Wait for critical data to load before doing anything
  // This prevents the "0 income" glitch when navigating to the page
  if (receiptsAsync is AsyncLoading || settingsAsync is AsyncLoading || profileAsync is AsyncLoading) {
    final cached = ref.read(_insightsCacheProvider);
    if (cached != null) return cached.data;
    // Fall through to actual values once loaded
  }

  final receipts = receiptsAsync.valueOrNull ?? [];
  final profile = profileAsync.valueOrNull;
  final currency = settingsAsync.valueOrNull?.currency ?? Currency.USD;
  
  final currentReceiptCount = receipts.length;
  final currentIncome = profile?.totalMonthlyIncome ?? 0.0;
  
  // 2. Check Cache
  final cachedInsights = ref.read(_insightsCacheProvider);
  
  // Only trigger re-generation if there's a meaningful change:
  // - Receipt added/deleted
  // - Income changed (and is non-zero)
  // - Currency changed
  final incomeChanged = (currentIncome > 0 && cachedInsights != null && currentIncome != cachedInsights.income);
  final receiptsChanged = cachedInsights == null || currentReceiptCount != cachedInsights.receiptCount;
  final currencyChanged = cachedInsights != null && currency != cachedInsights.data.currency;

  if (cachedInsights != null && !incomeChanged && !receiptsChanged && !currencyChanged) {
    return cachedInsights.data;
  }

  // 3. Calculate current state for insights
  final categorySpending = <ExpenseCategory, double>{};
  for (final receipt in receipts) {
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
      categorySpending[category] = (categorySpending[category] ?? 0.0) + monthlyAmount;
    }
  }
  
  final now = DateTime.now();
  final currentMonthReceipts = receipts.where((r) =>
    r.date.year == now.year && r.date.month == now.month
  ).toList();
  
  final receiptsSpending = currentMonthReceipts.fold<double>(0.0, (sum, r) => sum + r.total);
  final recurringSpending = profile?.totalMonthlyRecurringPayments ?? 0.0;
  final totalMonthlySpending = receiptsSpending + recurringSpending;
  
  final estimatedIncome = currentIncome > 0 ? currentIncome : 
      (totalMonthlySpending > 0 ? totalMonthlySpending * 1.5 : 0.0);
  
  // 4. Generate/Fetch Budget Plan
  Map<String, dynamic> budgetPlan;
  
  // ONLY call AI if income is valid and something changed
  if (estimatedIncome > 0 && (cachedInsights == null || receiptsChanged || incomeChanged || currencyChanged)) {
    final List<Map<String, dynamic>> recurringExpensesJson = profile?.recurringPayments.map((p) => {
      'name': p.name,
      'amount': p.amount,
      'frequency': p.frequency.name,
      'category': p.category ?? 'Other',
    }).toList() ?? [];

    final aiService = AIService();
    budgetPlan = await aiService.generateBudgetPlan(
      spendingHistory: categorySpending,
      monthlyIncome: estimatedIncome,
      monthsOfData: 1,
      recurringExpenses: recurringExpensesJson,
      currencyCode: currency.name,
    );

    // Auto-save the AI generated budget only if valid
    final suggestedBudgets = <ExpenseCategory, double>{};
    final budgetsJson = budgetPlan['budgets'] as Map<String, dynamic>?;
    if (budgetsJson != null && estimatedIncome > 0) {
      budgetsJson.forEach((key, value) {
        final category = ExpenseCategory.values.firstWhere(
          (c) => c.name == key,
          orElse: () => ExpenseCategory.other,
        );
        suggestedBudgets[category] = (value as num).toDouble();
      });

      final budget = Budget(
        monthlyTotal: estimatedIncome,
        categoryBudgets: suggestedBudgets,
        updatedAt: DateTime.now(),
      );
      
      // Persist the budget so other screens (Dashboard) see it
      Future.microtask(() => ref.read(budgetProvider.notifier).setBudget(budget));
    }
  } else if (cachedInsights != null) {
    budgetPlan = cachedInsights.data.budgetPlan;
  } else {
    // Last resort fallback if everything is loading/empty
    budgetPlan = {'budgets': {}, 'recommendations': [], 'savingsGoal': 0.0};
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
  
  // 5. Update Cache
  ref.read(_insightsCacheProvider.notifier).state = InsightsCache(
    data: insightsData,
    receiptCount: currentReceiptCount,
    income: currentIncome,
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
    final topCategory = categorySpending.entries.reduce((a, b) => a.value > b.value ? a : b);
    final categoryInfo = CategoryInfo.getInfo(topCategory.key);
    insights.add('Your top spending category is ${categoryInfo.name} (${categoryInfo.emoji}).');
  }
  final savingsRate = estimatedIncome > 0 ? ((estimatedIncome - monthlySpending) / estimatedIncome * 100) : 0;
  insights.add('Your current savings rate is ${savingsRate.toStringAsFixed(1)}%.');
  return insights;
}
