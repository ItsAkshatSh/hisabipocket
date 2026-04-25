import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisabi/core/models/dashboard_models.dart';
import 'package:hisabi/core/models/receipt_model.dart';
import 'package:hisabi/core/models/receipt_summary_model.dart';
import 'package:hisabi/core/widgets/widget_summary.dart';
import 'package:hisabi/features/receipts/providers/receipts_store.dart';
import 'package:hisabi/features/settings/providers/settings_provider.dart';
import 'package:hisabi/features/insights/providers/insights_provider.dart';
import 'package:hisabi/features/financial_profile/providers/financial_profile_provider.dart';
import 'package:hisabi/features/financial_profile/models/recurring_payment_model.dart';

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
  final profileAsync = ref.watch(financialProfileProvider);
  final profile = profileAsync.valueOrNull;

  final filteredReceipts = _filterByPeriod(receipts, period).toList();
  
  // Calculate total spent from receipts
  double receiptsTotal = filteredReceipts.fold<double>(0.0, (sum, r) => sum + r.total);
  
  // Calculate total spent from recurring payments (Pay-As-You-Go)
  double recurringTotal = 0.0;
  if (profile != null) {
    final now = DateTime.now();
    DateTime from;
    if (period == Period.allTime) {
      from = profile.recurringPayments.isEmpty 
          ? now 
          : profile.recurringPayments.map((p) => p.startDate).reduce((a, b) => a.isBefore(b) ? a : b);
    } else {
      from = period == Period.thisMonth ? _startOfMonth(now) : _startOfYear(now);
    }
    
    for (final p in profile.recurringPayments) {
      recurringTotal += _calculateOccurrencesInDashboardWindow(p, from, now);
    }
  }

  final totalSpent = receiptsTotal + recurringTotal;
  final receiptsCount = filteredReceipts.length;
  final averagePerReceipt =
      receiptsCount == 0 ? 0.0 : totalSpent / receiptsCount;

  // Compute top store by total spent
  final Map<String, double> byStore = {};
  for (final r in filteredReceipts) {
    byStore[r.store] = (byStore[r.store] ?? 0.0) + r.total;
  }
  
  // Add recurring merchants
  if (profile != null) {
    for (final p in profile.recurringPayments) {
      final amount = _calculateOccurrencesInDashboardWindow(p, _startOfMonth(DateTime.now()), DateTime.now());
      if (amount > 0) {
        byStore[p.name] = (byStore[p.name] ?? 0.0) + amount;
      }
    }
  }

  String topStore = '—';
  double topStoreTotal = 0.0;
  byStore.forEach((store, total) {
    if (total > topStoreTotal) {
      topStoreTotal = total;
      topStore = store;
    }
  });

  return DashboardStats(
    totalSpent: totalSpent,
    receiptsCount: receiptsCount,
    averagePerReceipt: averagePerReceipt,
    topStore: topStore,
    vsLastPeriodChange: 0.0,
    trend: 'flat',
  );
});

double _calculateOccurrencesInDashboardWindow(RecurringPayment payment, DateTime start, DateTime end) {
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

final widgetUpdateProvider = FutureProvider.autoDispose<void>((ref) async {
  final receiptsAsync = ref.watch(receiptsStoreProvider);
  final settingsAsync = ref.watch(settingsProvider);
  final profileAsync = ref.watch(financialProfileProvider);
  
  if (receiptsAsync is! AsyncData || settingsAsync is! AsyncData || profileAsync is! AsyncData) {
    return;
  }

  final receipts = receiptsAsync.value!;
  final settings = settingsAsync.value!;
  final profile = profileAsync.value!;
  final currencyCode = settings.currency.name;
  
  final now = DateTime.now();
  final monthStart = _startOfMonth(now);
  
  final currentMonthReceipts = receipts
      .where((r) => r.date.year == now.year && r.date.month == now.month)
      .toList();

  final receiptsTotal = currentMonthReceipts.fold<double>(0.0, (sum, r) => sum + r.total);
  
  double recurringTotal = 0.0;
  for (final p in profile.recurringPayments) {
    recurringTotal += _calculateOccurrencesInDashboardWindow(p, monthStart, now);
  }

  final totalThisMonth = receiptsTotal + recurringTotal;
  final receiptsCount = currentMonthReceipts.length;
  final averagePerReceipt = receiptsCount > 0 ? totalThisMonth / receiptsCount : 0.0;
  
  final daysWithExpenses = currentMonthReceipts
      .map((r) => DateTime(r.date.year, r.date.month, r.date.day))
      .toSet()
      .length;
  
  final totalItems = currentMonthReceipts.fold<int>(0, (sum, r) => sum + r.items.length);

  String topStore = '—';
  double topStoreTotal = 0.0;
  final byStore = <String, double>{};
  for (final r in currentMonthReceipts) {
    byStore[r.store] = (byStore[r.store] ?? 0.0) + r.total;
  }
  for (final p in profile.recurringPayments) {
    final amount = _calculateOccurrencesInDashboardWindow(p, monthStart, now);
    if (amount > 0) {
      byStore[p.name] = (byStore[p.name] ?? 0.0) + amount;
    }
  }
  byStore.forEach((store, total) {
    if (total > topStoreTotal) {
      topStoreTotal = total;
      topStore = store;
    }
  });

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
        weeklyChange: 0.0,
        monthlyChange: 0.0,
        isUp: false,
      ),
      savingsGoal: null,
    ),
    currencyCode: currencyCode,
    widgetSettings: settings.widgetSettings.toJson(),
  );
});
