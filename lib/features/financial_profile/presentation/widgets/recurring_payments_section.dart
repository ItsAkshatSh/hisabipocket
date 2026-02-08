import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisabi/core/utils/theme_extensions.dart';
import 'package:hisabi/features/financial_profile/models/recurring_payment_model.dart';
import 'package:hisabi/features/financial_profile/presentation/add_recurring_payment_modal.dart';
import 'package:hisabi/features/financial_profile/providers/financial_profile_provider.dart';
import 'package:hisabi/features/settings/providers/settings_provider.dart';
import 'package:intl/intl.dart';

class RecurringPaymentsSection extends ConsumerWidget {
  final List<RecurringPayment> payments;

  const RecurringPaymentsSection({
    super.key,
    required this.payments,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    final currency = settingsAsync.valueOrNull?.currency ?? Currency.USD;
    final formatter = NumberFormat.currency(
      symbol: currency.name,
      decimalDigits: 2,
    );

    return Column(
      children: [
        if (payments.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              children: [
                Icon(
                  Icons.repeat_outlined,
                  size: 48,
                  color: context.onSurfaceMutedColor.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No recurring payments',
                  style: TextStyle(
                    fontSize: 16,
                    color: context.onSurfaceMutedColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add subscriptions, bills, and other regular payments',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: context.onSurfaceMutedColor,
                  ),
                ),
              ],
            ),
          )
        else
          ...payments.map((payment) => _RecurringPaymentCard(
                payment: payment,
                formatter: formatter,
                onDelete: () {
                  ref
                      .read(financialProfileProvider.notifier)
                      .removeRecurringPayment(payment.id);
                },
              )),
      ],
    );
  }
}

class _RecurringPaymentCard extends StatelessWidget {
  final RecurringPayment payment;
  final NumberFormat formatter;
  final VoidCallback onDelete;

  const _RecurringPaymentCard({
    required this.payment,
    required this.formatter,
    required this.onDelete,
  });

  IconData _getIconData(String? iconName) {
    switch (iconName) {
      case 'netflix':
        return Icons.movie_outlined;
      case 'spotify':
        return Icons.music_note_outlined;
      case 'amazon':
        return Icons.shopping_bag_outlined;
      case 'youtube':
        return Icons.play_circle_outline;
      case 'phone':
        return Icons.phone_outlined;
      case 'home':
        return Icons.home_outlined;
      case 'fitness':
        return Icons.fitness_center_outlined;
      case 'wifi':
        return Icons.wifi_outlined;
      case 'bolt':
        return Icons.bolt_outlined;
      case 'shield':
        return Icons.shield_outlined;
      default:
        return Icons.payment_outlined;
    }
  }

  Color _getIconColor(String? iconName, BuildContext context) {
    switch (iconName) {
      case 'netflix':
        return const Color(0xFFE50914);
      case 'spotify':
        return const Color(0xFF1DB954);
      case 'amazon':
        return const Color(0xFFFF9900);
      case 'youtube':
        return const Color(0xFFFF0000);
      case 'phone':
        return const Color(0xFF2196F3);
      case 'home':
        return const Color(0xFF9C27B0);
      case 'fitness':
        return const Color(0xFF4CAF50);
      case 'wifi':
        return const Color(0xFF00BCD4);
      case 'bolt':
        return const Color(0xFFFFC107);
      case 'shield':
        return const Color(0xFF607D8B);
      default:
        return context.primaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final iconColor = _getIconColor(payment.iconName, context);
    final nextDue = payment.calculatedNextDueDate;
    final isDueSoon = nextDue.difference(DateTime.now()).inDays <= 7;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDueSoon
              ? context.primaryColor.withOpacity(0.3)
              : context.borderColor.withOpacity(0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.05,
            ),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _getIconData(payment.iconName),
              color: iconColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payment.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: context.onSurfaceColor,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      formatter.format(payment.amount),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: context.onSurfaceColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: context.borderColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        payment.frequencyLabel,
                        style: TextStyle(
                          fontSize: 11,
                          color: context.onSurfaceMutedColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Next: ${DateFormat('MMM d, y').format(nextDue)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDueSoon
                        ? context.primaryColor
                        : context.onSurfaceMutedColor,
                    fontWeight: isDueSoon ? FontWeight.w500 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
          // Delete Button
          IconButton(
            icon: Icon(
              Icons.delete_outline,
              size: 20,
              color: context.onSurfaceMutedColor,
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: context.surfaceColor,
                  title: const Text('Delete Payment?'),
                  content: Text(
                    'Are you sure you want to remove ${payment.name}?',
                    style: TextStyle(color: context.onSurfaceColor),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: context.onSurfaceMutedColor),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        onDelete();
                        Navigator.of(context).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.error,
                      ),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
