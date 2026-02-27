import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisabi/features/insights/models/recurring_expense.dart';
import 'package:hisabi/features/insights/providers/recurring_expenses_provider.dart';
import 'package:hisabi/features/financial_profile/providers/financial_profile_provider.dart';
import 'package:hisabi/features/financial_profile/models/recurring_payment_model.dart';
import 'package:hisabi/core/models/category_model.dart';
import 'package:intl/intl.dart';

class SubscriptionDetectiveCard extends ConsumerWidget {
  const SubscriptionDetectiveCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recurringAsync = ref.watch(recurringExpensesProvider);
    final profileAsync = ref.watch(financialProfileProvider);

    return recurringAsync.when(
      data: (expenses) {
        if (expenses.isEmpty) return const SizedBox.shrink();

        // Filter out expenses that are already in the financial profile
        final existingNames = profileAsync.valueOrNull?.recurringPayments
            .map((p) => p.name.toLowerCase().trim())
            .toSet() ?? {};
        
        final filteredExpenses = expenses
            .where((e) => !existingNames.contains(e.name.toLowerCase().trim()))
            .toList();

        if (filteredExpenses.isEmpty) return const SizedBox.shrink();

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.amber.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.search_rounded,
                        color: Colors.amber,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Subscription Detective',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'New recurring payments found',
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'I noticed these look like recurring subscriptions. Would you like to track them as monthly bills?',
                  style: TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                ...filteredExpenses.map((expense) => _SubscriptionItem(expense: expense)),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _SubscriptionItem extends ConsumerWidget {
  final RecurringExpense expense;

  const _SubscriptionItem({required this.expense});

  PaymentFrequency _mapFrequency(RecurrenceType type) {
    switch (type) {
      case RecurrenceType.weekly: return PaymentFrequency.weekly;
      case RecurrenceType.biweekly: return PaymentFrequency.biWeekly;
      case RecurrenceType.monthly: return PaymentFrequency.monthly;
      case RecurrenceType.quarterly: return PaymentFrequency.quarterly;
      case RecurrenceType.yearly: return PaymentFrequency.yearly;
      case RecurrenceType.irregular: return PaymentFrequency.monthly;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryInfo = CategoryInfo.getInfo(expense.category);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: categoryInfo.color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Text(categoryInfo.emoji, style: const TextStyle(fontSize: 20)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                Text(
                  '${expense.frequency.name.toUpperCase()} • Next: ${DateFormat('MMM d').format(expense.nextDue)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'AED ${expense.amount.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
              ),
              const SizedBox(height: 4),
              Text(
                '${(expense.confidence * 100).toInt()}% match',
                style: TextStyle(
                  fontSize: 10,
                  color: expense.confidence > 0.8 ? Colors.green : Colors.orange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () async {
              final newPayment = RecurringPayment(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                name: expense.name,
                amount: expense.amount,
                frequency: _mapFrequency(expense.frequency),
                startDate: expense.occurrences.first.date,
                nextDueDate: expense.nextDue,
                category: categoryInfo.name,
              );
              
              await ref.read(financialProfileProvider.notifier).addRecurringPayment(newPayment);
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${expense.name} added to Financial Profile'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            icon: const Icon(Icons.add_circle_outline, color: Colors.blue),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
