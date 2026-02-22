import 'package:flutter/material.dart';

enum PaymentFrequency { weekly, biWeekly, monthly, quarterly, yearly }

class RecurringPayment {
  final String id;
  final String name;
  final double amount;
  final PaymentFrequency frequency;
  final DateTime startDate;
  final DateTime? nextDueDate;
  final String? iconName; // For preset icons
  final String? category; // Optional category

  RecurringPayment({
    required this.id,
    required this.name,
    required this.amount,
    required this.frequency,
    required this.startDate,
    this.nextDueDate,
    this.iconName,
    this.category,
  });

  DateTime get calculatedNextDueDate {
    if (nextDueDate != null) return nextDueDate!;
    
    final now = DateTime.now();
    DateTime next = startDate;
    
    while (next.isBefore(now) || next.isAtSameMomentAs(now)) {
      switch (frequency) {
        case PaymentFrequency.weekly:
          next = next.add(const Duration(days: 7));
          break;
        case PaymentFrequency.biWeekly:
          next = next.add(const Duration(days: 14));
          break;
        case PaymentFrequency.monthly:
          next = DateTime(next.year, next.month + 1, next.day);
          break;
        case PaymentFrequency.quarterly:
          next = DateTime(next.year, next.month + 3, next.day);
          break;
        case PaymentFrequency.yearly:
          next = DateTime(next.year + 1, next.month, next.day);
          break;
      }
    }
    
    return next;
  }

  String get frequencyLabel {
    switch (frequency) {
      case PaymentFrequency.weekly:
        return 'Weekly';
      case PaymentFrequency.biWeekly:
        return 'Bi-weekly';
      case PaymentFrequency.monthly:
        return 'Monthly';
      case PaymentFrequency.quarterly:
        return 'Quarterly';
      case PaymentFrequency.yearly:
        return 'Yearly';
    }
  }

  String get previewText {
    final next = calculatedNextDueDate;
    switch (frequency) {
      case PaymentFrequency.weekly:
        return 'Repeats every week';
      case PaymentFrequency.biWeekly:
        return 'Repeats every 2 weeks';
      case PaymentFrequency.monthly:
        return 'Repeats on the ${next.day}${_getDaySuffix(next.day)} of every month';
      case PaymentFrequency.quarterly:
        return 'Repeats every 3 months';
      case PaymentFrequency.yearly:
        return 'Repeats on ${next.day} ${_getMonthName(next.month)} every year';
    }
  }

  String _getDaySuffix(int day) {
    if (day >= 11 && day <= 13) return 'th';
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }

  RecurringPayment copyWith({
    String? id,
    String? name,
    double? amount,
    PaymentFrequency? frequency,
    DateTime? startDate,
    DateTime? nextDueDate,
    String? iconName,
    String? category,
  }) {
    return RecurringPayment(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      frequency: frequency ?? this.frequency,
      startDate: startDate ?? this.startDate,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      iconName: iconName ?? this.iconName,
      category: category ?? this.category,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'amount': amount,
        'frequency': frequency.name,
        'startDate': startDate.toIso8601String(),
        'nextDueDate': nextDueDate?.toIso8601String(),
        'iconName': iconName,
        'category': category,
      };

  factory RecurringPayment.fromJson(Map<String, dynamic> json) {
    return RecurringPayment(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      frequency: json['frequency'] != null
          ? PaymentFrequency.values.firstWhere(
              (f) => f.name == json['frequency'],
              orElse: () => PaymentFrequency.monthly,
            )
          : PaymentFrequency.monthly,
      startDate: json['startDate'] != null
          ? DateTime.tryParse(json['startDate']) ?? DateTime.now()
          : DateTime.now(),
      nextDueDate: json['nextDueDate'] != null
          ? DateTime.tryParse(json['nextDueDate'])
          : null,
      iconName: json['iconName'] as String?,
      category: json['category'] as String?,
    );
  }
}

// Preset recurring payments
class RecurringPaymentPreset {
  final String name;
  final String iconName;
  final PaymentFrequency defaultFrequency;
  final String category;
  final Color? color;

  const RecurringPaymentPreset({
    required this.name,
    required this.iconName,
    required this.defaultFrequency,
    required this.category,
    this.color,
  });
}

final recurringPaymentPresets = [
  const RecurringPaymentPreset(
    name: 'Netflix',
    iconName: 'netflix',
    defaultFrequency: PaymentFrequency.monthly,
    category: 'Entertainment',
    color: Color(0xFFE50914),
  ),
  const RecurringPaymentPreset(
    name: 'Spotify',
    iconName: 'spotify',
    defaultFrequency: PaymentFrequency.monthly,
    category: 'Entertainment',
    color: Color(0xFF1DB954),
  ),
  const RecurringPaymentPreset(
    name: 'Amazon Prime',
    iconName: 'amazon',
    defaultFrequency: PaymentFrequency.monthly,
    category: 'Shopping',
    color: Color(0xFFFF9900),
  ),
  const RecurringPaymentPreset(
    name: 'YouTube Premium',
    iconName: 'youtube',
    defaultFrequency: PaymentFrequency.monthly,
    category: 'Entertainment',
    color: Color(0xFFFF0000),
  ),
  const RecurringPaymentPreset(
    name: 'Phone Bill',
    iconName: 'phone',
    defaultFrequency: PaymentFrequency.monthly,
    category: 'Utilities',
    color: Color(0xFF2196F3),
  ),
  const RecurringPaymentPreset(
    name: 'Rent',
    iconName: 'home',
    defaultFrequency: PaymentFrequency.monthly,
    category: 'Housing',
    color: Color(0xFF9C27B0),
  ),
  const RecurringPaymentPreset(
    name: 'Gym Membership',
    iconName: 'fitness',
    defaultFrequency: PaymentFrequency.monthly,
    category: 'Health',
    color: Color(0xFF4CAF50),
  ),
  const RecurringPaymentPreset(
    name: 'Internet',
    iconName: 'wifi',
    defaultFrequency: PaymentFrequency.monthly,
    category: 'Utilities',
    color: Color(0xFF00BCD4),
  ),
  const RecurringPaymentPreset(
    name: 'Electricity',
    iconName: 'bolt',
    defaultFrequency: PaymentFrequency.monthly,
    category: 'Utilities',
    color: Color(0xFFFFC107),
  ),
  const RecurringPaymentPreset(
    name: 'Insurance',
    iconName: 'shield',
    defaultFrequency: PaymentFrequency.monthly,
    category: 'Insurance',
    color: Color(0xFF607D8B),
  ),
];

