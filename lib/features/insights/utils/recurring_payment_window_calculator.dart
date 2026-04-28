import 'package:hisabi/features/financial_profile/models/recurring_payment_model.dart';

double calculateRecurringAmountInWindow(
  RecurringPayment payment,
  DateTime start,
  DateTime end,
) {
  int count = 0;
  DateTime current = payment.startDate;

  while (current.isBefore(start)) {
    current = nextRecurringOccurrenceDate(current, payment.frequency);
  }

  while (!current.isAfter(end)) {
    if (!current.isBefore(start)) {
      count++;
    }
    current = nextRecurringOccurrenceDate(current, payment.frequency);
  }

  return count * payment.amount;
}

DateTime nextRecurringOccurrenceDate(
  DateTime date,
  PaymentFrequency frequency,
) {
  switch (frequency) {
    case PaymentFrequency.weekly:
      return date.add(const Duration(days: 7));
    case PaymentFrequency.biWeekly:
      return date.add(const Duration(days: 14));
    case PaymentFrequency.monthly:
      return DateTime(date.year, date.month + 1, date.day);
    case PaymentFrequency.quarterly:
      return DateTime(date.year, date.month + 3, date.day);
    case PaymentFrequency.yearly:
      return DateTime(date.year + 1, date.month, date.day);
  }
}
