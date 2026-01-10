import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisabi/core/models/receipt_model.dart';
import 'package:hisabi/core/models/category_model.dart';
import 'package:hisabi/features/receipts/providers/receipts_store.dart';
import 'package:hisabi/features/insights/models/spending_alert.dart';
import 'package:hisabi/features/insights/models/insights_models.dart';
import 'package:hisabi/features/insights/providers/insights_provider.dart';

final spendingAlertsProvider = FutureProvider.autoDispose<List<SpendingAlert>>((ref) async {
  final receiptsAsync = ref.watch(receiptsStoreProvider);
  final receipts = receiptsAsync.valueOrNull ?? [];
  final insightsAsync = ref.watch(insightsProvider);
  final insights = insightsAsync.valueOrNull;
  
  if (receipts.isEmpty || insights == null) {
    return [];
  }
  
  final alerts = <SpendingAlert>[];
  final now = DateTime.now();
  
  // Get current month receipts
  final currentMonthReceipts = receipts.where((r) =>
    r.date.year == now.year && r.date.month == now.month
  ).toList();
  
  // Check for budget exceeded
  if (insights.suggestedBudgets != null) {
    for (final entry in insights.suggestedBudgets!.entries) {
      final category = ExpenseCategory.values.firstWhere(
        (c) => c.name == entry.key,
        orElse: () => ExpenseCategory.other,
      );
      final budget = entry.value;
      final currentSpending = insights.categorySpending[category] ?? 0.0;
      final percentage = budget > 0 ? (currentSpending / budget * 100) : 0;
      
      if (percentage >= 90 && percentage < 100) {
        alerts.add(SpendingAlert(
          type: AlertType.budgetExceeded,
          title: 'Budget Warning',
          message: 'You\'ve spent ${percentage.toStringAsFixed(0)}% of your ${CategoryInfo.getInfo(category).name} budget',
          amount: currentSpending,
          category: category,
          severity: AlertSeverity.warning,
          detectedAt: now,
          actionableSteps: [
            'Review recent purchases in this category',
            'Consider reducing spending for the rest of the month',
          ],
        ));
      } else if (percentage >= 100) {
        alerts.add(SpendingAlert(
          type: AlertType.budgetExceeded,
          title: 'Budget Exceeded',
          message: 'You\'ve exceeded your ${CategoryInfo.getInfo(category).name} budget by ${(percentage - 100).toStringAsFixed(0)}%',
          amount: currentSpending,
          category: category,
          severity: AlertSeverity.critical,
          detectedAt: now,
          actionableSteps: [
            'Review your spending in this category',
            'Adjust your budget for next month',
          ],
        ));
      }
    }
  }
  
  // Check for unusual spending (category spike)
  final lastMonthReceipts = receipts.where((r) {
    final lastMonth = now.subtract(const Duration(days: 30));
    return r.date.year == lastMonth.year && r.date.month == lastMonth.month;
  }).toList();
  
  if (lastMonthReceipts.isNotEmpty) {
    final lastMonthSpending = <ExpenseCategory, double>{};
    for (final receipt in lastMonthReceipts) {
      for (final item in receipt.items) {
        final category = item.category ?? ExpenseCategory.other;
        lastMonthSpending[category] = (lastMonthSpending[category] ?? 0.0) + item.total;
      }
    }
    
    for (final entry in insights.categorySpending.entries) {
      final category = entry.key;
      final current = entry.value;
      final previous = lastMonthSpending[category] ?? 0.0;
      
      if (previous > 0) {
        final changePercent = ((current - previous) / previous) * 100;
        if (changePercent > 50) {
          alerts.add(SpendingAlert(
            type: AlertType.categorySpike,
            title: 'Spending Spike Detected',
            message: 'Your ${CategoryInfo.getInfo(category).name} spending increased by ${changePercent.toStringAsFixed(0)}% compared to last month',
            amount: current,
            category: category,
            severity: changePercent > 100 ? AlertSeverity.critical : AlertSeverity.warning,
            detectedAt: now,
            actionableSteps: [
              'Review purchases in this category',
              'Check if this is a one-time expense',
            ],
          ));
        }
      }
    }
  }
  
  // Check for unusually large purchases
  if (currentMonthReceipts.isNotEmpty) {
    final averageReceipt = insights.monthlySpending / currentMonthReceipts.length;
    for (final receipt in currentMonthReceipts) {
      if (receipt.total > averageReceipt * 3 && receipt.total > 100) {
        alerts.add(SpendingAlert(
          type: AlertType.unusualSpending,
          title: 'Unusually Large Purchase',
          message: 'Purchase of ${receipt.total.toStringAsFixed(2)} at ${receipt.store} is 3x your average',
          amount: receipt.total,
          severity: AlertSeverity.info,
          detectedAt: receipt.date,
          actionableSteps: [
            'Verify this purchase is correct',
            'Review receipt details',
          ],
        ));
        break; // Only show one to avoid spam
      }
    }
  }
  
  // Sort by severity (critical first, then warning, then info)
  alerts.sort((a, b) {
    final severityOrder = {
      AlertSeverity.critical: 0,
      AlertSeverity.warning: 1,
      AlertSeverity.info: 2,
    };
    return severityOrder[a.severity]!.compareTo(severityOrder[b.severity]!);
  });
  
  return alerts;
});
