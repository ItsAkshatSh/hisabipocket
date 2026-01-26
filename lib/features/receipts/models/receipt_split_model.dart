import 'package:hisabi/core/models/category_model.dart';

class ReceiptSplit {
  final String id;
  final String label;
  final double amount;
  final ExpenseCategory? category;
  final String? notes;

  ReceiptSplit({
    required this.id,
    required this.label,
    required this.amount,
    this.category,
    this.notes,
  });

  ReceiptSplit copyWith({
    String? id,
    String? label,
    double? amount,
    ExpenseCategory? category,
    String? notes,
  }) {
    return ReceiptSplit(
      id: id ?? this.id,
      label: label ?? this.label,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'amount': amount,
        'category': category?.name,
        'notes': notes,
      };

  factory ReceiptSplit.fromJson(Map<String, dynamic> json) {
    return ReceiptSplit(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      label: json['label'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      category: json['category'] != null
          ? ExpenseCategory.values.firstWhere(
              (c) => c.name == json['category'],
              orElse: () => ExpenseCategory.other,
            )
          : null,
      notes: json['notes'] as String?,
    );
  }
}

