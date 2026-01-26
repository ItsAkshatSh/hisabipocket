import 'package:hisabi/core/models/category_model.dart';

class Budget {
  final double monthlyTotal;
  final Map<ExpenseCategory, double> categoryBudgets;
  final int startDay;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Budget({
    required this.monthlyTotal,
    Map<ExpenseCategory, double>? categoryBudgets,
    this.startDay = 1,
    DateTime? createdAt,
    this.updatedAt,
  })  : categoryBudgets = categoryBudgets ?? {},
        createdAt = createdAt ?? DateTime.now();

  double get totalCategoryBudgets {
    return categoryBudgets.values.fold(0.0, (sum, amount) => sum + amount);
  }

  double get remainingFromTotal {
    return monthlyTotal - totalCategoryBudgets;
  }

  Budget copyWith({
    double? monthlyTotal,
    Map<ExpenseCategory, double>? categoryBudgets,
    int? startDay,
    DateTime? updatedAt,
  }) {
    return Budget(
      monthlyTotal: monthlyTotal ?? this.monthlyTotal,
      categoryBudgets: categoryBudgets ?? Map.from(this.categoryBudgets),
      startDay: startDay ?? this.startDay,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'monthlyTotal': monthlyTotal,
        'categoryBudgets': categoryBudgets.map(
          (k, v) => MapEntry(k.name, v),
        ),
        'startDay': startDay,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      monthlyTotal: (json['monthlyTotal'] as num?)?.toDouble() ?? 0.0,
      categoryBudgets: json['categoryBudgets'] != null
          ? Map<ExpenseCategory, double>.from(
              (json['categoryBudgets'] as Map).map(
                (k, v) => MapEntry(
                  ExpenseCategory.values.firstWhere(
                    (c) => c.name == k,
                    orElse: () => ExpenseCategory.other,
                  ),
                  (v as num).toDouble(),
                ),
              ),
            )
          : {},
      startDay: json['startDay'] as int? ?? 1,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
    );
  }
}

class BudgetStatus {
  final double budgeted;
  final double spent;
  final double remaining;
  final double percentageUsed;
  final BudgetAlertLevel alertLevel;

  BudgetStatus({
    required this.budgeted,
    required this.spent,
  })  : remaining = budgeted - spent,
        percentageUsed = budgeted > 0 ? (spent / budgeted) * 100 : 0.0,
        alertLevel = budgeted > 0
            ? (spent / budgeted) >= 1.0
                ? BudgetAlertLevel.over
                : (spent / budgeted) >= 0.9
                    ? BudgetAlertLevel.warning
                    : (spent / budgeted) >= 0.8
                        ? BudgetAlertLevel.caution
                        : BudgetAlertLevel.good
            : BudgetAlertLevel.good;
}

enum BudgetAlertLevel {
  good,
  caution,
  warning,
  over,
}

