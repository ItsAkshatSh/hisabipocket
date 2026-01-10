import 'package:hisabi/core/models/category_model.dart';

enum PeriodType {
  month,
  quarter,
  year,
}

class PeriodComparison {
  final double currentAmount;
  final double previousAmount;
  final double changePercent;
  final String trend; // up, down, stable
  final PeriodType periodType;
  final Map<ExpenseCategory, CategoryComparison> categoryComparisons;
  final List<String> insights;

  PeriodComparison({
    required this.currentAmount,
    required this.previousAmount,
    required this.changePercent,
    required this.trend,
    required this.periodType,
    required this.categoryComparisons,
    this.insights = const [],
  });

  bool get isSignificant => changePercent.abs() > 10;
}

class CategoryComparison {
  final ExpenseCategory category;
  final double current;
  final double previous;
  final double change;
  final double changePercent;
  final String insight;
  final bool isSignificant; // >20% change

  CategoryComparison({
    required this.category,
    required this.current,
    required this.previous,
    required this.change,
    required this.changePercent,
    required this.insight,
    this.isSignificant = false,
  });
}
