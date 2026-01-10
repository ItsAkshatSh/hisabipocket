import 'package:hisabi/core/models/receipt_model.dart';
import 'package:hisabi/core/models/category_model.dart';

enum RecurrenceType {
  weekly,
  biweekly,
  monthly,
  quarterly,
  yearly,
  irregular,
}

class RecurringExpense {
  final String id;
  final String name;
  final double amount;
  final RecurrenceType frequency;
  final DateTime nextDue;
  final List<ReceiptModel> occurrences;
  final double? estimatedYearlyCost;
  final ExpenseCategory category;
  final double confidence; // 0.0 to 1.0
  final String? merchant;

  RecurringExpense({
    required this.id,
    required this.name,
    required this.amount,
    required this.frequency,
    required this.nextDue,
    required this.occurrences,
    this.estimatedYearlyCost,
    required this.category,
    required this.confidence,
    this.merchant,
  });

  double get monthlyCost {
    switch (frequency) {
      case RecurrenceType.weekly:
        return amount * 4.33;
      case RecurrenceType.biweekly:
        return amount * 2.17;
      case RecurrenceType.monthly:
        return amount;
      case RecurrenceType.quarterly:
        return amount / 3;
      case RecurrenceType.yearly:
        return amount / 12;
      case RecurrenceType.irregular:
        return amount;
    }
  }
}
