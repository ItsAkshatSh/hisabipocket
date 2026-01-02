import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisabi/core/models/dashboard_models.dart';
import 'package:hisabi/core/models/receipt_model.dart';
import 'package:hisabi/core/models/receipt_summary_model.dart';
import 'package:hisabi/features/receipts/providers/receipts_store.dart';

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
