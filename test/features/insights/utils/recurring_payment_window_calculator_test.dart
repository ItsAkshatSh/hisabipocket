import 'package:flutter_test/flutter_test.dart';
import 'package:hisabi/features/financial_profile/models/recurring_payment_model.dart';
import 'package:hisabi/features/insights/utils/recurring_payment_window_calculator.dart';

void main() {
  group('calculateRecurringAmountInWindow', () {
    test('counts monthly occurrences inside window inclusively', () {
      final payment = RecurringPayment(
        id: 'p1',
        name: 'Internet',
        amount: 50,
        frequency: PaymentFrequency.monthly,
        startDate: DateTime(2026, 1, 1),
      );

      final amount = calculateRecurringAmountInWindow(
        payment,
        DateTime(2026, 4, 1),
        DateTime(2026, 4, 30),
      );

      expect(amount, closeTo(50, 0.001));
    });

    test('counts weekly occurrences after advancing from old start date', () {
      final payment = RecurringPayment(
        id: 'p2',
        name: 'Gym',
        amount: 10,
        frequency: PaymentFrequency.weekly,
        startDate: DateTime(2026, 3, 1),
      );

      final amount = calculateRecurringAmountInWindow(
        payment,
        DateTime(2026, 4, 1),
        DateTime(2026, 4, 30),
      );

      expect(amount, closeTo(40, 0.001));
    });

    test('returns zero when no occurrence is in range', () {
      final payment = RecurringPayment(
        id: 'p3',
        name: 'Insurance',
        amount: 200,
        frequency: PaymentFrequency.yearly,
        startDate: DateTime(2026, 12, 1),
      );

      final amount = calculateRecurringAmountInWindow(
        payment,
        DateTime(2026, 4, 1),
        DateTime(2026, 4, 30),
      );

      expect(amount, closeTo(0, 0.001));
    });
  });
}
