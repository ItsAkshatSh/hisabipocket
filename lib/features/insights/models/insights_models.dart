import 'package:hisabi/core/models/category_model.dart';
import 'package:hisabi/features/settings/providers/settings_provider.dart';

class InsightsData {
  final Map<ExpenseCategory, double> categorySpending;
  final double monthlySpending;
  final double estimatedIncome;
  final Map<String, dynamic> budgetPlan;
  final List<String> insights;
  final Currency currency;
  
  InsightsData({
    required this.categorySpending,
    required this.monthlySpending,
    required this.estimatedIncome,
    required this.budgetPlan,
    required this.insights,
    required this.currency,
  });
  
  double get savingsRate {
    if (estimatedIncome == 0) return 0;
    return ((estimatedIncome - monthlySpending) / estimatedIncome) * 100;
  }
  
  Map<String, double>? get suggestedBudgets {
    final budgets = budgetPlan['budgets'] as Map<String, dynamic>?;
    if (budgets == null) return null;
    return budgets.map((key, value) => MapEntry(key, (value as num).toDouble()));
  }
  
  List<String>? get recommendations {
    final recs = budgetPlan['recommendations'] as List<dynamic>?;
    return recs?.map((e) => e.toString()).toList();
  }
  
  double? get savingsGoal {
    final goal = budgetPlan['savingsGoal'] as num?;
    return goal?.toDouble();
  }
}

