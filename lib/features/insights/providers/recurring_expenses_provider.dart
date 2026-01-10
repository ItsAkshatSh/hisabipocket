import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisabi/core/models/receipt_model.dart';
import 'package:hisabi/core/models/category_model.dart';
import 'package:hisabi/features/receipts/providers/receipts_store.dart';
import 'package:hisabi/features/insights/models/recurring_expense.dart';

final recurringExpensesProvider = FutureProvider.autoDispose<List<RecurringExpense>>((ref) async {
  final receiptsAsync = ref.watch(receiptsStoreProvider);
  final receipts = receiptsAsync.valueOrNull ?? [];
  
  if (receipts.length < 3) {
    return []; // Need at least 3 receipts to detect patterns
  }
  
  // Group receipts by store/merchant
  final byMerchant = <String, List<ReceiptModel>>{};
  for (final receipt in receipts) {
    final merchant = receipt.store.toLowerCase().trim();
    if (!byMerchant.containsKey(merchant)) {
      byMerchant[merchant] = [];
    }
    byMerchant[merchant]!.add(receipt);
  }
  
  final recurringExpenses = <RecurringExpense>[];
  
  for (final entry in byMerchant.entries) {
    final merchantReceipts = entry.value;
    if (merchantReceipts.length < 3) continue;
    
    // Sort by date
    merchantReceipts.sort((a, b) => a.date.compareTo(b.date));
    
    // Calculate average amount
    final total = merchantReceipts.fold<double>(0.0, (sum, r) => sum + r.total);
    final averageAmount = total / merchantReceipts.length;
    
    // Check if amounts are similar (±15% variance)
    final amountsSimilar = merchantReceipts.every((r) {
      final variance = (r.total - averageAmount).abs() / averageAmount;
      return variance <= 0.15;
    });
    
    if (!amountsSimilar) continue;
    
    // Calculate intervals between receipts
    final intervals = <int>[];
    for (int i = 1; i < merchantReceipts.length; i++) {
      final days = merchantReceipts[i].date.difference(merchantReceipts[i - 1].date).inDays;
      intervals.add(days);
    }
    
    // Detect frequency pattern
    RecurrenceType? frequency;
    double confidence = 0.0;
    
    if (intervals.isNotEmpty) {
      final avgInterval = intervals.reduce((a, b) => a + b) / intervals.length;
      
      // Check consistency (intervals should be similar)
      final isConsistent = intervals.every((interval) {
        final variance = (interval - avgInterval).abs() / avgInterval;
        return variance <= 0.3; // 30% variance allowed
      });
      
      if (isConsistent) {
        if (avgInterval >= 25 && avgInterval <= 35) {
          frequency = RecurrenceType.monthly;
          confidence = 0.9;
        } else if (avgInterval >= 6 && avgInterval <= 8) {
          frequency = RecurrenceType.weekly;
          confidence = 0.85;
        } else if (avgInterval >= 13 && avgInterval <= 15) {
          frequency = RecurrenceType.biweekly;
          confidence = 0.8;
        } else if (avgInterval >= 85 && avgInterval <= 95) {
          frequency = RecurrenceType.quarterly;
          confidence = 0.7;
        } else if (avgInterval >= 360 && avgInterval <= 370) {
          frequency = RecurrenceType.yearly;
          confidence = 0.6;
        } else {
          frequency = RecurrenceType.irregular;
          confidence = 0.5;
        }
      }
    }
    
    if (frequency != null && confidence >= 0.5) {
      // Calculate next due date
      final lastReceipt = merchantReceipts.last;
      DateTime nextDue;
      switch (frequency) {
        case RecurrenceType.weekly:
          nextDue = lastReceipt.date.add(const Duration(days: 7));
          break;
        case RecurrenceType.biweekly:
          nextDue = lastReceipt.date.add(const Duration(days: 14));
          break;
        case RecurrenceType.monthly:
          nextDue = DateTime(lastReceipt.date.year, lastReceipt.date.month + 1, lastReceipt.date.day);
          break;
        case RecurrenceType.quarterly:
          nextDue = DateTime(lastReceipt.date.year, lastReceipt.date.month + 3, lastReceipt.date.day);
          break;
        case RecurrenceType.yearly:
          nextDue = DateTime(lastReceipt.date.year + 1, lastReceipt.date.month, lastReceipt.date.day);
          break;
        case RecurrenceType.irregular:
          final avgDays = intervals.reduce((a, b) => a + b) / intervals.length;
          nextDue = lastReceipt.date.add(Duration(days: avgDays.round()));
          break;
      }
      
      // Get primary category
      final categoryCounts = <ExpenseCategory, int>{};
      for (final receipt in merchantReceipts) {
        for (final item in receipt.items) {
          final category = item.category ?? ExpenseCategory.other;
          categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
        }
      }
      final primaryCategory = categoryCounts.isEmpty
          ? ExpenseCategory.other
          : categoryCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
      
      // Calculate yearly cost
      double? yearlyCost;
      switch (frequency) {
        case RecurrenceType.weekly:
          yearlyCost = averageAmount * 52;
          break;
        case RecurrenceType.biweekly:
          yearlyCost = averageAmount * 26;
          break;
        case RecurrenceType.monthly:
          yearlyCost = averageAmount * 12;
          break;
        case RecurrenceType.quarterly:
          yearlyCost = averageAmount * 4;
          break;
        case RecurrenceType.yearly:
          yearlyCost = averageAmount;
          break;
        case RecurrenceType.irregular:
          yearlyCost = null;
          break;
      }
      
      recurringExpenses.add(RecurringExpense(
        id: '${entry.key}_${frequency.name}',
        name: entry.key.split(' ').map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1)).join(' '),
        amount: averageAmount,
        frequency: frequency,
        nextDue: nextDue,
        occurrences: merchantReceipts,
        estimatedYearlyCost: yearlyCost,
        category: primaryCategory,
        confidence: confidence,
        merchant: entry.key,
      ));
    }
  }
  
  // Sort by confidence (highest first)
  recurringExpenses.sort((a, b) => b.confidence.compareTo(a.confidence));
  
  return recurringExpenses;
});
