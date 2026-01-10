import 'package:hisabi/core/models/category_model.dart';
import 'package:hisabi/features/financial_profile/models/recurring_payment_model.dart';
import 'package:hisabi/features/settings/providers/settings_provider.dart';

enum EmploymentStatus { student, employed, freelancer, retired, other }

enum FinancialPriority { saving, debtPayoff, investing, spending }

class FinancialProfile {
  final double? monthlyIncome;
  final double? savingsGoalPercentage;
  final double? emergencyFundTarget;
  final Map<ExpenseCategory, double>? customBudgetLimits;
  final EmploymentStatus? employmentStatus;
  final int? familySize;
  final FinancialPriority? primaryPriority;
  final List<RecurringPayment> recurringPayments;
  final Currency? currency;
  final DateTime? lastUpdated;

  FinancialProfile({
    this.monthlyIncome,
    this.savingsGoalPercentage,
    this.emergencyFundTarget,
    this.customBudgetLimits,
    this.employmentStatus,
    this.familySize,
    this.primaryPriority,
    List<RecurringPayment>? recurringPayments,
    this.currency,
    this.lastUpdated,
  }) : recurringPayments = recurringPayments ?? [];

  double get totalMonthlyIncome => monthlyIncome ?? 0.0;

  bool get isComplete => monthlyIncome != null && monthlyIncome! > 0;

  double get totalMonthlyRecurringPayments {
    double total = 0.0;
    for (final payment in recurringPayments) {
      switch (payment.frequency) {
        case PaymentFrequency.weekly:
          total += payment.amount * 4.33; // Average weeks per month
          break;
        case PaymentFrequency.biWeekly:
          total += payment.amount * 2.17; // Average bi-weeks per month
          break;
        case PaymentFrequency.monthly:
          total += payment.amount;
          break;
        case PaymentFrequency.quarterly:
          total += payment.amount / 3;
          break;
        case PaymentFrequency.yearly:
          total += payment.amount / 12;
          break;
      }
    }
    return total;
  }

  FinancialProfile copyWith({
    double? monthlyIncome,
    double? savingsGoalPercentage,
    double? emergencyFundTarget,
    Map<ExpenseCategory, double>? customBudgetLimits,
    EmploymentStatus? employmentStatus,
    int? familySize,
    FinancialPriority? primaryPriority,
    List<RecurringPayment>? recurringPayments,
    Currency? currency,
    DateTime? lastUpdated,
  }) {
    return FinancialProfile(
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      savingsGoalPercentage:
          savingsGoalPercentage ?? this.savingsGoalPercentage,
      emergencyFundTarget: emergencyFundTarget ?? this.emergencyFundTarget,
      customBudgetLimits: customBudgetLimits ?? this.customBudgetLimits,
      employmentStatus: employmentStatus ?? this.employmentStatus,
      familySize: familySize ?? this.familySize,
      primaryPriority: primaryPriority ?? this.primaryPriority,
      recurringPayments: recurringPayments ?? this.recurringPayments,
      currency: currency ?? this.currency,
      lastUpdated: lastUpdated ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'monthlyIncome': monthlyIncome,
        'savingsGoalPercentage': savingsGoalPercentage,
        'emergencyFundTarget': emergencyFundTarget,
        'customBudgetLimits': customBudgetLimits?.map(
              (k, v) => MapEntry(k.name, v),
            ),
        'employmentStatus': employmentStatus?.name,
        'familySize': familySize,
        'primaryPriority': primaryPriority?.name,
        'recurringPayments': recurringPayments.map((p) => p.toJson()).toList(),
        'currency': currency?.name,
        'lastUpdated': lastUpdated?.toIso8601String(),
      };

  factory FinancialProfile.fromJson(Map<String, dynamic> json) {
    return FinancialProfile(
      monthlyIncome: (json['monthlyIncome'] as num?)?.toDouble(),
      savingsGoalPercentage:
          (json['savingsGoalPercentage'] as num?)?.toDouble(),
      emergencyFundTarget: (json['emergencyFundTarget'] as num?)?.toDouble(),
      customBudgetLimits: json['customBudgetLimits'] != null
          ? Map<ExpenseCategory, double>.from(
              (json['customBudgetLimits'] as Map).map(
                (k, v) => MapEntry(
                  ExpenseCategory.values.firstWhere(
                    (c) => c.name == k,
                    orElse: () => ExpenseCategory.other,
                  ),
                  (v as num).toDouble(),
                ),
              ),
            )
          : null,
      employmentStatus: json['employmentStatus'] != null
          ? EmploymentStatus.values.firstWhere(
              (e) => e.name == json['employmentStatus'],
              orElse: () => EmploymentStatus.other,
            )
          : null,
      familySize: json['familySize'] as int?,
      primaryPriority: json['primaryPriority'] != null
          ? FinancialPriority.values.firstWhere(
              (p) => p.name == json['primaryPriority'],
              orElse: () => FinancialPriority.saving,
            )
          : null,
      recurringPayments: json['recurringPayments'] != null
          ? (json['recurringPayments'] as List)
              .map((p) => RecurringPayment.fromJson(
                    Map<String, dynamic>.from(p),
                  ))
              .toList()
          : [],
      currency: json['currency'] != null
          ? Currency.values.firstWhere(
              (c) => c.name == json['currency'],
              orElse: () => Currency.USD,
            )
          : null,
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.tryParse(json['lastUpdated'])
          : null,
    );
  }
}

