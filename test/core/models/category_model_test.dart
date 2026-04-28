import 'package:flutter_test/flutter_test.dart';
import 'package:hisabi/core/models/category_model.dart';

void main() {
  group('CategoryInfo.mapStringToCategory', () {
    test('maps food merchants and terms to food', () {
      expect(
        CategoryInfo.mapStringToCategory('Starbucks Coffee'),
        ExpenseCategory.food,
      );
      expect(
        CategoryInfo.mapStringToCategory('Grocery Supermarket'),
        ExpenseCategory.food,
      );
    });

    test('maps transport fuel context to transport', () {
      expect(
        CategoryInfo.mapStringToCategory('Shell gas station'),
        ExpenseCategory.transport,
      );
      expect(
        CategoryInfo.mapStringToCategory('Uber trip'),
        ExpenseCategory.transport,
      );
    });

    test('maps subscriptions and media services correctly', () {
      expect(
        CategoryInfo.mapStringToCategory('YouTube Premium Monthly'),
        ExpenseCategory.subscriptions,
      );
      expect(
        CategoryInfo.mapStringToCategory('Spotify membership'),
        ExpenseCategory.subscriptions,
      );
    });

    test('uses other for weak or ambiguous text', () {
      expect(CategoryInfo.mapStringToCategory('premium plan'), ExpenseCategory.other);
      expect(CategoryInfo.mapStringToCategory('misc charge'), ExpenseCategory.other);
    });

    test('handles punctuation and mixed casing', () {
      expect(
        CategoryInfo.mapStringToCategory('NETFLIX, INC.'),
        ExpenseCategory.subscriptions,
      );
      expect(
        CategoryInfo.mapStringToCategory('City Hospital #12'),
        ExpenseCategory.health,
      );
    });
  });
}
