import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisabi/core/models/receipt_model.dart';
import 'package:hisabi/core/models/category_model.dart';
import 'package:hisabi/features/receipts/providers/receipts_store.dart';
import 'package:hisabi/features/wrapped/models/wrapped_models.dart';
import 'package:hisabi/features/settings/providers/settings_provider.dart';
import 'package:intl/intl.dart';

DateTime _getWeekStart(DateTime date) {
  final weekday = date.weekday;
  return date.subtract(Duration(days: weekday - 1));
}

final weekWrappedProvider = FutureProvider.autoDispose.family<WeekWrapped, DateTime?>((ref, weekStart) async {
  final receiptsAsync = ref.watch(receiptsStoreProvider);
  final receipts = receiptsAsync.valueOrNull ?? [];
  
  final settingsAsync = ref.watch(settingsProvider);
  final currency = settingsAsync.valueOrNull?.currency ?? Currency.USD;
  
  // Calculate the correct start date for the wrap
  final now = DateTime.now();
  
  final sundayOffset = now.weekday == 7 ? 0 : now.weekday;
  final lastSunday = DateTime(now.year, now.month, now.day).subtract(Duration(days: sundayOffset));
  final startOfWrappedWeek = lastSunday.subtract(const Duration(days: 6));
  
  final start = weekStart ?? startOfWrappedWeek;
  final end = DateTime(start.year, start.month, start.day, 23, 59, 59).add(const Duration(days: 6));
  
  final weekReceipts = receipts.where((r) => 
    r.date.isAfter(start.subtract(const Duration(seconds: 1))) &&
    r.date.isBefore(end.add(const Duration(seconds: 1)))
  ).toList();
  
  return _generateWrapped(weekReceipts, start, end, currency.name);
});

Future<WeekWrapped> _generateWrapped(
  List<ReceiptModel> receipts,
  DateTime start,
  DateTime end,
  String currencyCode,
) async {
  final stats = _calculateStats(receipts);
  final personality = _determinePersonality(receipts);
  final funFacts = _generateFunFacts(receipts, stats);
  final topMoments = _getTopMoments(receipts);
  
  final formatter = NumberFormat.simpleCurrency(name: currencyCode, decimalDigits: 2);
  
  // Generate cards
  final cards = <WrappedCard>[
    _createOpeningCard(start, end),
    _createTotalSpentCard(stats, formatter),
    if (stats.topCategory != null) _createTopCategoryCard(stats, formatter),
    _createTopStoreCard(stats, formatter),
    _createBiggestPurchaseCard(stats, formatter),
    _createBusiestDayCard(stats),
    _createPersonalityCard(personality),
    if (funFacts.isNotEmpty) _createFunFactCard(funFacts.first),
    _createClosingCard(),
  ];
  
  return WeekWrapped(
    weekStart: start,
    weekEnd: end,
    stats: stats,
    cards: cards,
    personality: personality,
    funFacts: funFacts,
    topMoments: topMoments,
  );
}

WrappedStats _calculateStats(List<ReceiptModel> receipts) {
  if (receipts.isEmpty) {
    return WrappedStats(
      totalSpent: 0.0,
      receiptsCount: 0,
      uniqueStores: 0,
      averagePerReceipt: 0.0,
      topStore: '—',
      topStoreSpending: 0.0,
      categoryBreakdown: {},
      busiestDay: '—',
      biggestPurchase: '—',
      biggestPurchaseAmount: 0.0,
      biggestPurchaseStore: '—',
      daysWithSpending: 0,
      dailyAverage: 0.0,
    );
  }
  
  final totalSpent = receipts.fold<double>(0.0, (sum, r) => sum + r.total);
  final receiptsCount = receipts.length;
  final uniqueStores = receipts.map((r) => r.store).toSet().length;
  final averagePerReceipt = totalSpent / receiptsCount;
  
  // Top store
  final storeTotals = <String, double>{};
  for (final r in receipts) {
    storeTotals[r.store] = (storeTotals[r.store] ?? 0.0) + r.total;
  }
  String topStore = '—';
  double topStoreSpending = 0.0;
  storeTotals.forEach((store, total) {
    if (total > topStoreSpending) {
      topStoreSpending = total;
      topStore = store;
    }
  });
  
  // Category breakdown
  final categoryTotals = <ExpenseCategory, double>{};
  for (final receipt in receipts) {
    for (final item in receipt.items) {
      final category = item.category ?? ExpenseCategory.other;
      categoryTotals[category] = (categoryTotals[category] ?? 0.0) + item.total;
    }
  }
  
  final categoryBreakdown = categoryTotals.map((key, value) => 
    MapEntry(key.name, value)
  );
  
  ExpenseCategory? topCategory;
  double topCategorySpending = 0.0;
  categoryTotals.forEach((category, total) {
    if (total > topCategorySpending) {
      topCategorySpending = total;
      topCategory = category;
    }
  });
  
  // Busiest day
  final dayTotals = <String, double>{};
  final dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  for (final r in receipts) {
    final dayName = dayNames[r.date.weekday - 1];
    dayTotals[dayName] = (dayTotals[dayName] ?? 0.0) + r.total;
  }
  String busiestDay = '—';
  double busiestDayTotal = 0.0;
  dayTotals.forEach((day, total) {
    if (total > busiestDayTotal) {
      busiestDayTotal = total;
      busiestDay = day;
    }
  });
  
  // Biggest purchase
  ReceiptModel? biggestReceipt;
  double biggestAmount = 0.0;
  for (final r in receipts) {
    if (r.total > biggestAmount) {
      biggestAmount = r.total;
      biggestReceipt = r;
    }
  }
  
  final daysWithSpending = receipts
      .map((r) => DateTime(r.date.year, r.date.month, r.date.day))
      .toSet()
      .length;
  final dailyAverage = daysWithSpending > 0 ? totalSpent / daysWithSpending : 0.0;
  
  return WrappedStats(
    totalSpent: totalSpent,
    receiptsCount: receiptsCount,
    uniqueStores: uniqueStores,
    averagePerReceipt: averagePerReceipt,
    topStore: topStore,
    topStoreSpending: topStoreSpending,
    categoryBreakdown: categoryBreakdown,
    busiestDay: busiestDay,
    biggestPurchase: biggestReceipt?.name ?? '—',
    biggestPurchaseAmount: biggestAmount,
    biggestPurchaseStore: biggestReceipt?.store ?? '—',
    daysWithSpending: daysWithSpending,
    dailyAverage: dailyAverage,
    topCategory: topCategory,
    topCategorySpending: topCategorySpending,
  );
}

SpendingPersonality _determinePersonality(List<ReceiptModel> receipts) {
  if (receipts.isEmpty) {
    return SpendingPersonality(
      type: 'Silent Observer',
      description: 'You haven\'t logged enough spending this week to find your pattern yet!',
      emoji: '',
      traits: ['Private', 'Minimalist'],
    );
  }
  
  // Check weekend vs weekday spending
  double weekendTotal = 0.0;
  double weekdayTotal = 0.0;
  for (final r in receipts) {
    if (r.date.weekday >= 6) {
      weekendTotal += r.total;
    } else {
      weekdayTotal += r.total;
    }
  }
  
  final weekendPercentage = weekendTotal / (weekendTotal + weekdayTotal);
  
  if (weekendPercentage > 0.6) {
    return SpendingPersonality(
      type: 'Weekend Warrior',
      description: 'You live for the weekend! Most of your spending happens Fri-Sun',
      emoji: '',
      traits: ['Weekend-focused', 'Social spender'],
    );
  }
  
  // Check for bulk vs frequent purchases
  final avgReceiptSize = receipts.fold<double>(0.0, (sum, r) => sum + r.total) / receipts.length;
  if (avgReceiptSize > 100 && receipts.length < 5) {
    return SpendingPersonality(
      type: 'Bulk Buyer',
      description: 'You prefer fewer, larger purchases',
      emoji: '',
      traits: ['Strategic', 'Planned'],
    );
  }
  
  if (receipts.length > 10) {
    return SpendingPersonality(
      type: 'Daily Shopper',
      description: 'You make many small purchases throughout the week',
      emoji: '',
      traits: ['Frequent', 'Active'],
    );
  }
  
  return SpendingPersonality(
    type: 'Balanced Spender',
    description: 'You maintain a healthy spending balance',
    emoji: '',
    traits: ['Consistent', 'Moderate'],
  );
}

List<FunFact> _generateFunFacts(List<ReceiptModel> receipts, WrappedStats stats) {
  final facts = <FunFact>[];
  
  if (receipts.isEmpty) return facts;
  
  // Coffee vs food
  double coffeeTotal = 0.0;
  double foodTotal = 0.0;
  for (final r in receipts) {
    for (final item in r.items) {
      final name = item.name.toLowerCase();
      if (name.contains('coffee') || name.contains('latte') || name.contains('cappuccino')) {
        coffeeTotal += item.total;
      }
      if (item.category == ExpenseCategory.food) {
        foodTotal += item.total;
      }
    }
  }
  
  if (coffeeTotal > foodTotal && coffeeTotal > 0) {
    facts.add(FunFact(
      fact: 'You spent more on coffee than general food!',
      context: 'That\'s a lot of caffeine!',
      emoji: '',
    ));
  }
  
  // Most visited store
  if (stats.uniqueStores > 0) {
    final storeVisits = <String, int>{};
    for (final r in receipts) {
      storeVisits[r.store] = (storeVisits[r.store] ?? 0) + 1;
    }
    final mostVisited = storeVisits.entries.reduce((a, b) => a.value > b.value ? a : b);
    if (mostVisited.value > 2) {
      facts.add(FunFact(
        fact: 'You visited ${mostVisited.key} ${mostVisited.value} times this week',
        context: 'Your go-to spot!',
        emoji: '',
      ));
    }
  }
  
  // Average per day
  if (stats.daysWithSpending > 0) {
    facts.add(FunFact(
      fact: 'You logged spending on ${stats.daysWithSpending} out of 7 days',
      context: 'Keeping consistent!',
      emoji: '',
    ));
  }
  
  return facts;
}

List<TopMoment> _getTopMoments(List<ReceiptModel> receipts) {
  if (receipts.isEmpty) return [];
  
  final sorted = List<ReceiptModel>.from(receipts)
    ..sort((a, b) => b.total.compareTo(a.total));
  
  return sorted.take(3).map((r) => TopMoment(
    title: r.name,
    description: 'Your biggest purchase this week',
    amount: r.total,
    date: r.date,
    store: r.store,
  )).toList();
}

WrappedCard _createOpeningCard(DateTime start, DateTime end) {
  final formatter = DateFormat('MMM d');
  return WrappedCard(
    type: CardType.opening,
    title: 'Your Week Wrapped',
    subtitle: '${formatter.format(start)} - ${formatter.format(end)}',
    mainValue: 'Ready to see how you spent this week?',
    backgroundColor: const Color(0xFF1DB954), // Spotify green
    textColor: Colors.white,
    emoji: '',
  );
}

WrappedCard _createTotalSpentCard(WrappedStats stats, NumberFormat formatter) {
  return WrappedCard(
    type: CardType.totalSpent,
    title: 'You spent',
    subtitle: 'this week',
    mainValue: formatter.format(stats.totalSpent),
    secondaryValue: 'Across ${stats.receiptsCount} receipts at ${stats.uniqueStores} stores',
    backgroundColor: const Color(0xFF8B5CF6),
    textColor: Colors.white,
    emoji: '',
  );
}

WrappedCard _createTopCategoryCard(WrappedStats stats, NumberFormat formatter) {
  final categoryInfo = CategoryInfo.getInfo(stats.topCategory!);
  final percentage = stats.totalSpent > 0 
      ? ((stats.topCategorySpending / stats.totalSpent) * 100).toStringAsFixed(0)
      : '0';
  
  return WrappedCard(
    type: CardType.topCategory,
    title: 'Your top category',
    subtitle: '${percentage}% of your spending',
    mainValue: categoryInfo.name,
    secondaryValue: formatter.format(stats.topCategorySpending),
    backgroundColor: categoryInfo.color,
    textColor: Colors.white,
    emoji: '',
  );
}

WrappedCard _createTopStoreCard(WrappedStats stats, NumberFormat formatter) {
  return WrappedCard(
    type: CardType.topStore,
    title: 'Your favorite spot',
    subtitle: 'Total spent: ${formatter.format(stats.topStoreSpending)}',
    mainValue: stats.topStore,
    secondaryValue: 'You visited this store the most',
    backgroundColor: const Color(0xFFFF6B6B),
    textColor: Colors.white,
    emoji: '',
  );
}

WrappedCard _createBiggestPurchaseCard(WrappedStats stats, NumberFormat formatter) {
  return WrappedCard(
    type: CardType.biggestPurchase,
    title: 'Your biggest purchase',
    subtitle: 'at ${stats.biggestPurchaseStore}',
    mainValue: formatter.format(stats.biggestPurchaseAmount),
    secondaryValue: stats.biggestPurchase,
    backgroundColor: const Color(0xFF4ECDC4),
    textColor: Colors.white,
    emoji: '',
  );
}

WrappedCard _createBusiestDayCard(WrappedStats stats) {
  return WrappedCard(
    type: CardType.busiestDay,
    title: 'Your busiest spending day',
    subtitle: 'Most of the action happened here',
    mainValue: stats.busiestDay,
    secondaryValue: 'Make sure to rest next week!',
    backgroundColor: const Color(0xFFFFD93D),
    textColor: Colors.black87,
    emoji: '',
  );
}

WrappedCard _createPersonalityCard(SpendingPersonality personality) {
  return WrappedCard(
    type: CardType.personality,
    title: 'You\'re a',
    subtitle: personality.description,
    mainValue: personality.type,
    secondaryValue: personality.traits.join(' • '),
    backgroundColor: const Color(0xFF6C5CE7),
    textColor: Colors.white,
    emoji: '',
  );
}

WrappedCard _createFunFactCard(FunFact funFact) {
  return WrappedCard(
    type: CardType.funFact,
    title: 'Fun Fact',
    subtitle: funFact.context,
    mainValue: funFact.fact,
    backgroundColor: const Color(0xFFFF9FF3),
    textColor: Colors.white,
    emoji: '',
  );
}

WrappedCard _createClosingCard() {
  return WrappedCard(
    type: CardType.closing,
    title: 'That\'s your week!',
    subtitle: 'Keep tracking to see next week\'s story',
    mainValue: 'Done',
    backgroundColor: const Color(0xFF1DB954),
    textColor: Colors.white,
    emoji: '',
  );
}
