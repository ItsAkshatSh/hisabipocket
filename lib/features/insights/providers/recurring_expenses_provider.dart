import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisabi/core/models/receipt_model.dart';
import 'package:hisabi/core/models/category_model.dart';
import 'package:hisabi/features/receipts/providers/receipts_store.dart';
import 'package:hisabi/features/insights/models/recurring_expense.dart';
import 'package:hisabi/core/services/ai_service.dart';

final recurringExpensesProvider = FutureProvider.autoDispose<List<RecurringExpense>>((ref) async {
  final receiptsAsync = ref.watch(receiptsStoreProvider);
  final receipts = receiptsAsync.valueOrNull ?? [];
  
  if (receipts.length < 2) {
    return []; 
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
  
  final detectedRecurring = <RecurringExpense>[];
  final aiService = AIService();
  
  for (final entry in byMerchant.entries) {
    final merchantReceipts = entry.value;
    if (merchantReceipts.length < 2) continue; // Now checking even with 2 receipts
    
    // Sort by date
    merchantReceipts.sort((a, b) => a.date.compareTo(b.date));
    
    // Check for "Subscription-like" merchants or names (e.g., Netflix, Spotify, Gym, Rent)
    final isKnownSubscriptionType = _isLikelySubscription(entry.key);
    
    // Calculate average amount
    final total = merchantReceipts.fold<double>(0.0, (sum, r) => sum + r.total);
    final averageAmount = total / merchantReceipts.length;
    
    // Check if amounts are similar (±10% variance for subscriptions is usually tight)
    final amountsSimilar = merchantReceipts.every((r) {
      final variance = (r.total - averageAmount).abs() / averageAmount;
      return variance <= 0.1;
    });
    
    if (!amountsSimilar && !isKnownSubscriptionType) continue;
    
    // Calculate intervals
    final intervals = <int>[];
    for (int i = 1; i < merchantReceipts.length; i++) {
      final days = merchantReceipts[i].date.difference(merchantReceipts[i - 1].date).inDays;
      intervals.add(days);
    }
    
    RecurrenceType? frequency;
    double confidence = 0.0;
    
    if (intervals.isNotEmpty) {
      final avgInterval = intervals.reduce((a, b) => a + b) / intervals.length;
      
      // Tight subscription detection
      if (avgInterval >= 27 && avgInterval <= 33) {
        frequency = RecurrenceType.monthly;
        confidence = isKnownSubscriptionType ? 0.95 : 0.85;
      } else if (avgInterval >= 6 && avgInterval <= 8) {
        frequency = RecurrenceType.weekly;
        confidence = 0.8;
      } else if (avgInterval >= 360 && avgInterval <= 370) {
        frequency = RecurrenceType.yearly;
        confidence = 0.9;
      }
    }
    
    // Special case: Only 2 receipts but perfectly matching subscription merchant
    if (frequency == null && merchantReceipts.length == 2 && isKnownSubscriptionType) {
      final daysBetween = merchantReceipts[1].date.difference(merchantReceipts[0].date).inDays;
      if (daysBetween >= 27 && daysBetween <= 33) {
        frequency = RecurrenceType.monthly;
        confidence = 0.75;
      }
    }
    
    if (frequency != null) {
      final lastReceipt = merchantReceipts.last;
      DateTime nextDue = _calculateNextDue(lastReceipt.date, frequency);
      
      detectedRecurring.add(RecurringExpense(
        id: '${entry.key}_${frequency.name}',
        name: _capitalize(entry.key),
        amount: averageAmount,
        frequency: frequency,
        nextDue: nextDue,
        occurrences: merchantReceipts,
        category: _detectPrimaryCategory(merchantReceipts),
        confidence: confidence,
        merchant: entry.key,
      ));
    }
  }
  
  detectedRecurring.sort((a, b) => b.confidence.compareTo(a.confidence));
  return detectedRecurring;
});

bool _isLikelySubscription(String merchant) {
  final subscriptions = [
    'netflix', 'spotify', 'apple', 'google', 'amazon prime', 'disney', 'hulu',
    'gym', 'fitness', 'rent', 'utility', 'internet', 'mobile', 'telecom', 'du', 'etisalat',
    'youtube', 'ps plus', 'xbox', 'microsoft', 'adobe', 'canva', 'chatgpt'
  ];
  final lower = merchant.toLowerCase();
  return subscriptions.any((s) => lower.contains(s));
}

DateTime _calculateNextDue(DateTime lastDate, RecurrenceType frequency) {
  switch (frequency) {
    case RecurrenceType.weekly: return lastDate.add(const Duration(days: 7));
    case RecurrenceType.biweekly: return lastDate.add(const Duration(days: 14));
    case RecurrenceType.monthly: return DateTime(lastDate.year, lastDate.month + 1, lastDate.day);
    case RecurrenceType.quarterly: return DateTime(lastDate.year, lastDate.month + 3, lastDate.day);
    case RecurrenceType.yearly: return DateTime(lastDate.year + 1, lastDate.month, lastDate.day);
    case RecurrenceType.irregular: return lastDate.add(const Duration(days: 30));
  }
}

ExpenseCategory _detectPrimaryCategory(List<ReceiptModel> receipts) {
  final counts = <ExpenseCategory, int>{};
  for (final r in receipts) {
    final cat = r.primaryCategory ?? r.calculatedPrimaryCategory ?? ExpenseCategory.other;
    counts[cat] = (counts[cat] ?? 0) + 1;
  }
  return counts.isEmpty ? ExpenseCategory.other : counts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
}

String _capitalize(String s) => s.split(' ').map((w) => w.isEmpty ? '' : w[0].toUpperCase() + w.substring(1)).join(' ');
