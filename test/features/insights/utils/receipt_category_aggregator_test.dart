import 'package:flutter_test/flutter_test.dart';
import 'package:hisabi/core/models/category_model.dart';
import 'package:hisabi/core/models/receipt_model.dart';
import 'package:hisabi/features/insights/utils/receipt_category_aggregator.dart';

void main() {
  group('accumulateReceiptIntoCategoryTotals', () {
    test('uses receipt total when items are empty', () {
      final totals = <ExpenseCategory, double>{};
      final receipt = ReceiptModel(
        id: 'r1',
        name: 'Rent payment',
        date: DateTime(2026, 4, 1),
        store: 'Landlord',
        items: const [],
        total: 1200,
        primaryCategory: ExpenseCategory.housing,
      );

      accumulateReceiptIntoCategoryTotals(receipt, totals);

      expect(totals[ExpenseCategory.housing], closeTo(1200, 0.001));
    });

    test('uses item categories when items exist', () {
      final totals = <ExpenseCategory, double>{};
      final receipt = ReceiptModel(
        id: 'r2',
        name: 'Groceries',
        date: DateTime(2026, 4, 2),
        store: 'Market',
        items: [
          ReceiptItem(
            name: 'Fruit',
            quantity: 1,
            price: 15,
            total: 15,
            category: ExpenseCategory.food,
          ),
          ReceiptItem(
            name: 'Shampoo',
            quantity: 1,
            price: 20,
            total: 20,
            category: ExpenseCategory.lifestyle,
          ),
        ],
        total: 35,
        primaryCategory: ExpenseCategory.food,
      );

      accumulateReceiptIntoCategoryTotals(receipt, totals);

      expect(totals[ExpenseCategory.food], closeTo(15, 0.001));
      expect(totals[ExpenseCategory.lifestyle], closeTo(20, 0.001));
    });

    test('adds fallback delta when item sum differs from receipt total', () {
      final totals = <ExpenseCategory, double>{};
      final receipt = ReceiptModel(
        id: 'r3',
        name: 'Mixed basket',
        date: DateTime(2026, 4, 3),
        store: 'Supermarket',
        items: [
          ReceiptItem(
            name: 'Apple',
            quantity: 1,
            price: 20,
            total: 20,
            category: ExpenseCategory.food,
          ),
          ReceiptItem(
            name: 'Soap',
            quantity: 1,
            price: 10,
            total: 10,
            category: ExpenseCategory.health,
          ),
        ],
        total: 40,
        primaryCategory: ExpenseCategory.food,
      );

      accumulateReceiptIntoCategoryTotals(receipt, totals);

      expect(totals[ExpenseCategory.food], closeTo(30, 0.001));
      expect(totals[ExpenseCategory.health], closeTo(10, 0.001));
    });
  });
}
