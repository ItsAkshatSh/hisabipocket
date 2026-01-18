import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisabi/core/models/dashboard_models.dart';
import 'package:hisabi/core/models/receipt_model.dart';
import 'package:hisabi/core/models/receipt_summary_model.dart';
import 'package:hisabi/core/widgets/widget_summary.dart';
import 'package:hisabi/features/receipts/providers/receipts_store.dart';
import 'package:hisabi/features/settings/providers/settings_provider.dart';
import 'package:hisabi/features/insights/providers/insights_provider.dart';
import 'package:hisabi/features/financial_profile/providers/financial_profile_provider.dart';

enum Period { thisMonth, thisYear, allTime }

final periodProvider = StateProvider<Period>((ref) => Period.thisMonth);

DateTime _startOfMonth(DateTime now) =>
    DateTime(now.year, now.month, 1);

DateTime _startOfYear(DateTime now) =>
    DateTime(now.year, 1, 1);

Iterable<ReceiptModel> _filterByPeriod(
  List<ReceiptModel> receipts,
  Period period,
) {
  if (period == Period.allTime) return receipts;
  final now = DateTime.now();
  final from =
      period == Period.thisMonth ? _startOfMonth(now) : _startOfYear(now);
  return receipts.where((r) => !r.date.isBefore(from));
}

final dashboardStatsProvider =
    FutureProvider.autoDispose<DashboardStats>((ref) async {
  final period = ref.watch(periodProvider);
  final receiptsAsync = ref.watch(receiptsStoreProvider);
  final receipts = receiptsAsync.valueOrNull ?? [];

  final filtered = _filterByPeriod(receipts, period).toList();
  final totalSpent =
      filtered.fold<double>(0.0, (sum, r) => sum + r.total);
  final receiptsCount = filtered.length;
  final averagePerReceipt =
      receiptsCount == 0 ? 0.0 : totalSpent / receiptsCount;

  // Compute top store by total spent
  final Map<String, double> byStore = {};
  for (final r in filtered) {
    byStore[r.store] = (byStore[r.store] ?? 0.0) + r.total;
  }
  String topStore = '—';
  double topStoreTotal = 0.0;
  byStore.forEach((store, total) {
    if (total > topStoreTotal) {
      topStoreTotal = total;
      topStore = store;
    }
  });

  // For now, we don't have historical comparison, so keep it flat.
  const vsLastPeriodChange = 0.0;
  const trend = 'flat';

  return DashboardStats(
    totalSpent: totalSpent,
    receiptsCount: receiptsCount,
    averagePerReceipt: averagePerReceipt,
    topStore: topStore,
    vsLastPeriodChange: vsLastPeriodChange,
    trend: trend,
  );
});

final recentReceiptsProvider =
    FutureProvider.autoDispose<List<ReceiptSummaryModel>>((ref) async {
  final receiptsAsync = ref.watch(receiptsStoreProvider);
  final receipts = receiptsAsync.valueOrNull ?? [];
  final recent = receipts.reversed.take(10).map((r) {
    return ReceiptSummaryModel(
      id: r.id,
      name: r.name,
      savedAt: r.date,
      total: r.total,
      itemCount: r.items.length,
      store: r.store,
    );
  }).toList();
  return recent;
});

final quickStatsProvider =
    FutureProvider.autoDispose<QuickStats>((ref) async {
  final receiptsAsync = ref.watch(receiptsStoreProvider);
  final receipts = receiptsAsync.valueOrNull ?? [];
  if (receipts.isEmpty) {
    return QuickStats(
      highestExpense: 0.0,
      lowestExpense: 0.0,
      daysWithExpenses: 0,
      totalItems: 0,
    );
  }

  final totals = receipts.map((r) => r.total).toList()..sort();
  final highestExpense = totals.last;
  final lowestExpense = totals.first;

  final daysWithExpenses = receipts
      .map((r) => DateTime(r.date.year, r.date.month, r.date.day))
      .toSet()
      .length;

  final totalItems =
      receipts.fold<int>(0, (sum, r) => sum + r.items.length);

  return QuickStats(
    highestExpense: highestExpense,
    lowestExpense: lowestExpense,
    daysWithExpenses: daysWithExpenses,
    totalItems: totalItems,
  );
});

// Widget update provider - watches receipts and updates widget automatically
final widgetUpdateProvider = FutureProvider.autoDispose<void>((ref) async {
  final receiptsAsync = ref.watch(receiptsStoreProvider);
  final settingsAsync = ref.watch(settingsProvider);
  
  // Only update when receipts are loaded (not loading or error)
  return receiptsAsync.when(
    data: (receipts) async {
      final settings = settingsAsync.valueOrNull;
      final currencyCode = settings?.currency.name ?? 'USD';
      final widgetSettings = settings?.widgetSettings;
      
      final now = DateTime.now();
      final currentMonth = receipts
          .where((r) => r.date.year == now.year && r.date.month == now.month)
          .toList();

      final totalThisMonth =
          currentMonth.fold<double>(0.0, (sum, r) => sum + r.total);
      final receiptsCount = currentMonth.length;
      final averagePerReceipt = receiptsCount > 0 ? totalThisMonth / receiptsCount : 0.0;
      
      final daysWithExpenses = currentMonth
          .map((r) => DateTime(r.date.year, r.date.month, r.date.day))
          .toSet()
          .length;
      
      final totalItems = currentMonth.fold<int>(0, (sum, r) => sum + r.items.length);

      String topStore = '—';
      double topStoreTotal = 0.0;
      for (final r in currentMonth) {
        final tally = currentMonth
            .where((x) => x.store == r.store)
            .fold<double>(0.0, (sum, x) => sum + x.total);
        if (tally > topStoreTotal) {
          topStoreTotal = tally;
          topStore = r.store;
        }
      }

      // Calculate Monthly Trend
      final lastMonth = receipts
          .where((r) => r.date.year == (now.month == 1 ? now.year - 1 : now.year) && 
                        r.date.month == (now.month == 1 ? 12 : now.month - 1))
          .toList();
      final totalLastMonth = lastMonth.fold<double>(0.0, (sum, r) => sum + r.total);
      final monthlyChange = totalLastMonth == 0 ? 0.0 : ((totalThisMonth - totalLastMonth) / totalLastMonth) * 100;

      // Calculate Weekly Trend
      final weekAgo = now.subtract(const Duration(days: 7));
      final lastWeek = currentMonth
          .where((r) => r.date.isAfter(weekAgo))
          .toList();
      final totalLastWeek = lastWeek.fold<double>(0.0, (sum, r) => sum + r.total);
      final previousWeek = currentMonth
          .where((r) => r.date.isBefore(weekAgo) && r.date.isAfter(weekAgo.subtract(const Duration(days: 7))))
          .toList();
      final totalPreviousWeek = previousWeek.fold<double>(0.0, (sum, r) => sum + r.total);
      final weeklyChange = totalPreviousWeek == 0 ? 0.0 : ((totalLastWeek - totalPreviousWeek) / totalPreviousWeek) * 100;

      // Calculate Monthly Budget for Savings Goal
      final insightsAsync = ref.read(insightsProvider);
      final insights = insightsAsync.valueOrNull;
      final profileAsync = ref.read(financialProfileProvider);
      final profile = profileAsync.valueOrNull;
      
      double monthlyBudget = 0.0;
      if (insights != null && insights.suggestedBudgets != null) {
        // Sum all suggested budgets
        monthlyBudget = insights.suggestedBudgets!.values.fold<double>(0.0, (sum, budget) => sum + budget);
      } else if (profile != null && profile.totalMonthlyIncome > 0) {
        // Use income minus savings goal if available
        final savingsPercentage = profile.savingsGoalPercentage ?? 20.0;
        monthlyBudget = profile.totalMonthlyIncome * (1 - savingsPercentage / 100);
      } else if (insights != null && insights.estimatedIncome > 0) {
        // Fallback: use estimated income minus 20% savings
        monthlyBudget = insights.estimatedIncome * 0.8;
      } else {
        // Last resort: use 1.5x of current spending as budget estimate
        monthlyBudget = totalThisMonth > 0 ? totalThisMonth * 1.5 : 0.0;
      }

      await saveAndUpdateWidgetSummary(
        WidgetSummary(
          totalThisMonth: totalThisMonth,
          topStore: topStore,
          receiptsCount: receiptsCount,
          averagePerReceipt: averagePerReceipt,
          daysWithExpenses: daysWithExpenses,
          totalItems: totalItems,
          updatedAt: DateTime.now(),
          expenseTrend: ExpenseTrend(
            weeklyChange: weeklyChange,
            monthlyChange: monthlyChange,
            isUp: totalThisMonth > totalLastMonth,
          ),
          savingsGoal: monthlyBudget > 0 ? SavingsGoal(
            title: 'Monthly Limit',
            targetAmount: monthlyBudget,
            currentAmount: totalThisMonth,
            targetDate: DateTime(now.year, now.month + 1, 1),
          ) : null,
        ),
        currencyCode: currencyCode,
        widgetSettings: widgetSettings?.toJson(),
      );
    },
    loading: () async {},
    error: (_, __) async {},
  );
});
