import 'package:flutter/material.dart';
import 'package:hisabi/core/models/category_model.dart';

class WeekWrapped {
  final DateTime weekStart;
  final DateTime weekEnd;
  final WrappedStats stats;
  final List<WrappedCard> cards;
  final SpendingPersonality personality;
  final List<FunFact> funFacts;
  final List<TopMoment> topMoments;
  
  WeekWrapped({
    required this.weekStart,
    required this.weekEnd,
    required this.stats,
    required this.cards,
    required this.personality,
    required this.funFacts,
    required this.topMoments,
  });
}

class WrappedStats {
  final double totalSpent;
  final int receiptsCount;
  final int uniqueStores;
  final double averagePerReceipt;
  final String topStore;
  final double topStoreSpending;
  final Map<String, double> categoryBreakdown;
  final String busiestDay;
  final String biggestPurchase;
  final double biggestPurchaseAmount;
  final String biggestPurchaseStore;
  final int daysWithSpending;
  final double dailyAverage;
  final ExpenseCategory? topCategory;
  final double topCategorySpending;
  
  WrappedStats({
    required this.totalSpent,
    required this.receiptsCount,
    required this.uniqueStores,
    required this.averagePerReceipt,
    required this.topStore,
    required this.topStoreSpending,
    required this.categoryBreakdown,
    required this.busiestDay,
    required this.biggestPurchase,
    required this.biggestPurchaseAmount,
    required this.biggestPurchaseStore,
    required this.daysWithSpending,
    required this.dailyAverage,
    this.topCategory,
    this.topCategorySpending = 0.0,
  });
}

class WrappedCard {
  final CardType type;
  final String title;
  final String subtitle;
  final String mainValue;
  final String? secondaryValue;
  final Color backgroundColor;
  final Color textColor;
  final String? emoji;
  final List<String>? highlights;
  
  WrappedCard({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.mainValue,
    this.secondaryValue,
    required this.backgroundColor,
    required this.textColor,
    this.emoji,
    this.highlights,
  });
}

enum CardType {
  opening,
  totalSpent,
  topCategory,
  topStore,
  biggestPurchase,
  busiestDay,
  personality,
  funFact,
  comparison,
  closing,
}

class SpendingPersonality {
  final String type;
  final String description;
  final String emoji;
  final List<String> traits;
  
  SpendingPersonality({
    required this.type,
    required this.description,
    required this.emoji,
    required this.traits,
  });
}

class FunFact {
  final String fact;
  final String context;
  final String emoji;
  
  FunFact({
    required this.fact,
    required this.context,
    required this.emoji,
  });
}

class TopMoment {
  final String title;
  final String description;
  final double amount;
  final DateTime date;
  final String? store;
  
  TopMoment({
    required this.title,
    required this.description,
    required this.amount,
    required this.date,
    this.store,
  });
}

