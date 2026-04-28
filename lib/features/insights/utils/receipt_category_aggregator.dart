import 'package:hisabi/core/models/category_model.dart';
import 'package:hisabi/core/models/receipt_model.dart';

void accumulateReceiptIntoCategoryTotals(
  ReceiptModel receipt,
  Map<ExpenseCategory, double> totals,
) {
  final fallbackCategory = CategoryInfo.mapStringToCategory(
    receipt.primaryCategory?.name ?? receipt.store,
  );

  if (receipt.items.isEmpty) {
    totals[fallbackCategory] = (totals[fallbackCategory] ?? 0.0) + receipt.total;
    return;
  }

  double itemsTotal = 0.0;
  for (final item in receipt.items) {
    final itemCategory =
        CategoryInfo.mapStringToCategory(item.category?.name ?? item.name);
    totals[itemCategory] = (totals[itemCategory] ?? 0.0) + item.total;
    itemsTotal += item.total;
  }

  // Align category totals with the receipt total.
  final delta = receipt.total - itemsTotal;
  if (delta.abs() > 0.01) {
    totals[fallbackCategory] = (totals[fallbackCategory] ?? 0.0) + delta;
  }
}

Map<ExpenseCategory, double> aggregateReceiptsByCategory(
  Iterable<ReceiptModel> receipts,
) {
  final totals = <ExpenseCategory, double>{};
  for (final receipt in receipts) {
    accumulateReceiptIntoCategoryTotals(receipt, totals);
  }
  return totals;
}
