import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';

class CategorySpending {
  final String category;
  final String emoji;
  final double amount;
  final Color color;

  const CategorySpending({
    required this.category,
    required this.emoji,
    required this.amount,
    required this.color,
  });

  Map<String, dynamic> toJson() => {
        'category': category,
        'emoji': emoji,
        'amount': amount,
        'color': color.value,
      };

  factory CategorySpending.fromJson(Map<String, dynamic> json) {
    return CategorySpending(
      category: json['category'] as String? ?? '',
      emoji: json['emoji'] as String? ?? '📦',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      color: Color(json['color'] as int? ?? 0xFF9E9E9E),
    );
  }
}

class ExpenseTrend {
  final double weeklyChange;
  final double monthlyChange;
  final bool isUp;

  const ExpenseTrend({
    required this.weeklyChange,
    required this.monthlyChange,
    required this.isUp,
  });

  Map<String, dynamic> toJson() => {
        'weeklyChange': weeklyChange,
        'monthlyChange': monthlyChange,
        'isUp': isUp,
      };

  factory ExpenseTrend.fromJson(Map<String, dynamic> json) {
    return ExpenseTrend(
      weeklyChange: (json['weeklyChange'] as num?)?.toDouble() ?? 0.0,
      monthlyChange: (json['monthlyChange'] as num?)?.toDouble() ?? 0.0,
      isUp: json['isUp'] as bool? ?? false,
    );
  }
}

class SavingsGoal {
  final String title;
  final double targetAmount;
  final double currentAmount;
  final DateTime targetDate;

  const SavingsGoal({
    required this.title,
    required this.targetAmount,
    required this.currentAmount,
    required this.targetDate,
  });

  double get progress => currentAmount / targetAmount;
  bool get isCompleted => currentAmount >= targetAmount;

  Map<String, dynamic> toJson() => {
        'title': title,
        'targetAmount': targetAmount,
        'currentAmount': currentAmount,
        'targetDate': targetDate.toIso8601String(),
      };

  factory SavingsGoal.fromJson(Map<String, dynamic> json) {
    return SavingsGoal(
      title: json['title'] as String? ?? 'Savings Goal',
      targetAmount: (json['targetAmount'] as num?)?.toDouble() ?? 0.0,
      currentAmount: (json['currentAmount'] as num?)?.toDouble() ?? 0.0,
      targetDate: DateTime.tryParse(json['targetDate'] as String? ?? '') ?? DateTime.now().add(const Duration(days: 30)),
    );
  }
}

class WidgetSummary {
  final double totalThisMonth;
  final String topStore;
  final int receiptsCount;
  final double averagePerReceipt;
  final int daysWithExpenses;
  final int totalItems;
  final DateTime updatedAt;

  // New widget data
  final double? monthlyBudget;
  final List<CategorySpending> topCategories;
  final ExpenseTrend? expenseTrend;
  final SavingsGoal? savingsGoal;

  const WidgetSummary({
    required this.totalThisMonth,
    required this.topStore,
    this.receiptsCount = 0,
    this.averagePerReceipt = 0.0,
    this.daysWithExpenses = 0,
    this.totalItems = 0,
    required this.updatedAt,
    this.monthlyBudget,
    this.topCategories = const [],
    this.expenseTrend,
    this.savingsGoal,
  });

  Map<String, dynamic> toJson() => {
        'totalThisMonth': totalThisMonth,
        'topStore': topStore,
        'receiptsCount': receiptsCount,
        'averagePerReceipt': averagePerReceipt,
        'daysWithExpenses': daysWithExpenses,
        'totalItems': totalItems,
        'updatedAt': updatedAt.toIso8601String(),
      };

  static WidgetSummary fromJson(Map<String, dynamic> json) {
    return WidgetSummary(
      totalThisMonth: (json['totalThisMonth'] as num?)?.toDouble() ?? 0,
      topStore: (json['topStore'] as String?) ?? '—',
      receiptsCount: (json['receiptsCount'] as num?)?.toInt() ?? 0,
      averagePerReceipt: (json['averagePerReceipt'] as num?)?.toDouble() ?? 0.0,
      daysWithExpenses: (json['daysWithExpenses'] as num?)?.toInt() ?? 0,
      totalItems: (json['totalItems'] as num?)?.toInt() ?? 0,
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
      monthlyBudget: (json['monthlyBudget'] as num?)?.toDouble(),
      topCategories: (json['topCategories'] as List<dynamic>?)
              ?.map((c) => CategorySpending.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
      expenseTrend: json['expenseTrend'] != null
          ? ExpenseTrend.fromJson(json['expenseTrend'] as Map<String, dynamic>)
          : null,
      savingsGoal: json['savingsGoal'] != null
          ? SavingsGoal.fromJson(json['savingsGoal'] as Map<String, dynamic>)
          : null,
    );
  }
}

/// Save summary data for the home widget and trigger a widget refresh.
Future<void> saveAndUpdateWidgetSummary(
  WidgetSummary summary, {
  String androidProvider = 'HisabiWidgetProvider',
  String? iosProvider,
  String? currencyCode,
  Map<String, dynamic>? widgetSettings,
}) async {
  await HomeWidget.saveWidgetData<String>(
    'widget_summary',
    jsonEncode(summary.toJson()),
  );
  
  if (currencyCode != null) {
    await HomeWidget.saveWidgetData<String>('currency_code', currencyCode);
  }
  
  if (widgetSettings != null) {
    await HomeWidget.saveWidgetData<String>(
      'widget_settings',
      jsonEncode(widgetSettings),
    );
  }

  await HomeWidget.updateWidget(
    name: androidProvider,
    iOSName: iosProvider,
  );
}
