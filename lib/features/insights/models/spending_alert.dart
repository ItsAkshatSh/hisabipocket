import 'package:hisabi/core/models/category_model.dart';

enum AlertType {
  budgetExceeded,
  unusualSpending,
  recurringExpenseDetected,
  savingsOpportunity,
  trendAlert,
  categorySpike,
}

enum AlertSeverity {
  info,
  warning,
  critical,
}

class SpendingAlert {
  final AlertType type;
  final String title;
  final String message;
  final double? amount;
  final ExpenseCategory? category;
  final AlertSeverity severity;
  final DateTime detectedAt;
  final List<String> actionableSteps;

  SpendingAlert({
    required this.type,
    required this.title,
    required this.message,
    this.amount,
    this.category,
    required this.severity,
    required this.detectedAt,
    this.actionableSteps = const [],
  });
}
