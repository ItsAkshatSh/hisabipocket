import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisabi/features/financial_profile/models/recurring_payment_model.dart';
import 'package:hisabi/features/financial_profile/providers/financial_profile_provider.dart';
import 'package:hisabi/features/financial_profile/presentation/add_recurring_payment_modal.dart';
import 'package:hisabi/features/settings/providers/settings_provider.dart';
import 'package:intl/intl.dart';

class RecurringBillsScreen extends ConsumerWidget {
  const RecurringBillsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(financialProfileProvider);
    final settingsAsync = ref.watch(settingsProvider);
    final currency = settingsAsync.valueOrNull?.currency ?? Currency.USD;
    final formatter = NumberFormat.currency(symbol: currency.name, decimalDigits: 2);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recurring Bills'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddModal(context, ref),
          ),
        ],
      ),
      body: profileAsync.when(
        data: (profile) {
          final payments = profile.recurringPayments;
          
          if (payments.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.repeat_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No recurring bills yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add your recurring bills to track them automatically',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _showAddModal(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Recurring Bill'),
                  ),
                ],
              ),
            );
          }

          final totalMonthly = profile.totalMonthlyRecurringPayments;

          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Monthly',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          formatter.format(totalMonthly),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (profile.monthlyIncome != null && profile.monthlyIncome! > 0) ...[
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: (totalMonthly / profile.monthlyIncome!).clamp(0.0, 1.0),
                        minHeight: 6,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${((totalMonthly / profile.monthlyIncome!) * 100).toStringAsFixed(1)}% of monthly income',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: payments.length,
                  itemBuilder: (context, index) {
                    final payment = payments[index];
                    final nextDue = payment.calculatedNextDueDate;
                    final daysUntilDue = nextDue.difference(DateTime.now()).inDays;
                    
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _getIconForPayment(payment),
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        title: Text(
                          payment.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text('${payment.frequencyLabel} • ${formatter.format(payment.amount)}'),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  Icons.calendar_today,
                                  size: 14,
                                  color: daysUntilDue <= 7
                                      ? Colors.red
                                      : daysUntilDue <= 30
                                          ? Colors.orange
                                          : Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  daysUntilDue < 0
                                      ? 'Overdue by ${-daysUntilDue} days'
                                      : daysUntilDue == 0
                                          ? 'Due today'
                                          : daysUntilDue == 1
                                              ? 'Due tomorrow'
                                              : 'Due in $daysUntilDue days',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: daysUntilDue <= 7
                                        ? Colors.red
                                        : daysUntilDue <= 30
                                            ? Colors.orange
                                            : Colors.grey,
                                    fontWeight: daysUntilDue <= 7 ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton(
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              child: const Row(
                                children: [
                                  Icon(Icons.edit, size: 18),
                                  SizedBox(width: 8),
                                  Text('Edit'),
                                ],
                              ),
                              onTap: () {
                                Future.delayed(Duration.zero, () {
                                  _showEditModal(context, ref, payment);
                                });
                              },
                            ),
                            PopupMenuItem(
                              child: const Row(
                                children: [
                                  Icon(Icons.delete, size: 18, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Delete', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                              onTap: () {
                                Future.delayed(Duration.zero, () {
                                  _confirmDelete(context, ref, payment.id);
                                });
                              },
                            ),
                          ],
                        ),
                        onTap: () => _showEditModal(context, ref, payment),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  IconData _getIconForPayment(RecurringPayment payment) {
    if (payment.iconName != null) {
      switch (payment.iconName) {
        case 'home':
          return Icons.home;
        case 'car':
          return Icons.directions_car;
        case 'phone':
          return Icons.phone;
        case 'wifi':
          return Icons.wifi;
        case 'credit_card':
          return Icons.credit_card;
        case 'subscriptions':
          return Icons.subscriptions;
        default:
          return Icons.repeat;
      }
    }
    return Icons.repeat;
  }

  void _showAddModal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddRecurringPaymentModal(),
    );
  }

  void _showEditModal(BuildContext context, WidgetRef ref, RecurringPayment payment) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Recurring Bill'),
        content: const Text('Editing functionality will be available in the add modal. For now, please delete and recreate the bill.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String paymentId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Recurring Bill?'),
        content: const Text('Are you sure you want to delete this recurring bill?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(financialProfileProvider.notifier).removeRecurringPayment(paymentId);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

