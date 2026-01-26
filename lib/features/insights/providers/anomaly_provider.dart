import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisabi/core/models/receipt_model.dart';
import 'package:hisabi/features/receipts/providers/receipts_store.dart';
import 'package:hisabi/core/models/category_model.dart';

class Anomaly {
  final ReceiptModel receipt;
  final AnomalyType type;
  final String reason;
  final double deviation;

  Anomaly({
    required this.receipt,
    required this.type,
    required this.reason,
    required this.deviation,
  });
}

enum AnomalyType {
  unusuallyHigh,
  unusuallyLow,
  unusualCategory,
  unusualStore,
  unusualTime,
}

final anomalyProvider = FutureProvider.autoDispose<List<Anomaly>>((ref) async {
  final receiptsAsync = ref.watch(receiptsStoreProvider);
  final receipts = receiptsAsync.valueOrNull ?? [];

  if (receipts.length < 3) {
    return [];
  }

  final anomalies = <Anomaly>[];

  final amounts = receipts.map((r) => r.total).toList()..sort();
  final median = amounts[amounts.length ~/ 2];
  final q1 = amounts[amounts.length ~/ 4];
  final q3 = amounts[(amounts.length * 3) ~/ 4];
  final iqr = q3 - q1;
  final upperBound = q3 + (1.5 * iqr);
  final lowerBound = q1 - (1.5 * iqr);

  final categoryCounts = <ExpenseCategory, int>{};
  final storeCounts = <String, int>{};
  final hourCounts = <int, int>{};

  for (final receipt in receipts) {
    final category = receipt.primaryCategory ?? receipt.calculatedPrimaryCategory;
    if (category != null) {
      categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
    }
    storeCounts[receipt.store] = (storeCounts[receipt.store] ?? 0) + 1;
    hourCounts[receipt.date.hour] = (hourCounts[receipt.date.hour] ?? 0) + 1;
  }

  final topCategory = categoryCounts.isEmpty
      ? null
      : categoryCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  final topStore = storeCounts.isEmpty
      ? null
      : storeCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  final commonHours = hourCounts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final mostCommonHour = commonHours.isEmpty ? null : commonHours.first.key;

  for (final receipt in receipts) {
    final category = receipt.primaryCategory ?? receipt.calculatedPrimaryCategory;

    if (receipt.total > upperBound) {
      anomalies.add(Anomaly(
        receipt: receipt,
        type: AnomalyType.unusuallyHigh,
        reason: 'Amount is significantly higher than usual (${((receipt.total / median - 1) * 100).toStringAsFixed(0)}% above median)',
        deviation: receipt.total / median,
      ));
    }

    if (receipt.total < lowerBound && receipt.total > 0) {
      anomalies.add(Anomaly(
        receipt: receipt,
        type: AnomalyType.unusuallyLow,
        reason: 'Amount is significantly lower than usual',
        deviation: median / receipt.total,
      ));
    }

    if (topCategory != null && category != null && category != topCategory) {
      final categoryRatio = (categoryCounts[category] ?? 0) / receipts.length;
      if (categoryRatio < 0.1) {
        anomalies.add(Anomaly(
          receipt: receipt,
          type: AnomalyType.unusualCategory,
          reason: 'Unusual category: ${category.name} (only ${(categoryRatio * 100).toStringAsFixed(0)}% of receipts)',
          deviation: 1.0 / categoryRatio,
        ));
      }
    }

    if (topStore != null && receipt.store != topStore) {
      final storeRatio = (storeCounts[receipt.store] ?? 0) / receipts.length;
      if (storeRatio < 0.05) {
        anomalies.add(Anomaly(
          receipt: receipt,
          type: AnomalyType.unusualStore,
          reason: 'Unusual store: ${receipt.store} (only ${(storeRatio * 100).toStringAsFixed(0)}% of receipts)',
          deviation: 1.0 / storeRatio,
        ));
      }
    }

    if (mostCommonHour != null) {
      final hourDiff = (receipt.date.hour - mostCommonHour).abs();
      if (hourDiff > 6) {
        anomalies.add(Anomaly(
          receipt: receipt,
          type: AnomalyType.unusualTime,
          reason: 'Unusual time: ${receipt.date.hour}:00 (most common is $mostCommonHour:00)',
          deviation: hourDiff.toDouble(),
        ));
      }
    }
  }

  anomalies.sort((a, b) => b.deviation.compareTo(a.deviation));
  return anomalies.take(10).toList();
});

