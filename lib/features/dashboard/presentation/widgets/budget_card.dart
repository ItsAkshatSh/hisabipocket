import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hisabi/features/budgets/models/budget_model.dart';
import 'package:hisabi/features/budgets/providers/budget_provider.dart';
import 'package:hisabi/features/settings/providers/settings_provider.dart';
import 'package:intl/intl.dart';

class BudgetCard extends ConsumerWidget {
  const BudgetCard({super.key});

  Color _levelColor(BuildContext context, BudgetAlertLevel level) {
    final cs = Theme.of(context).colorScheme;
    switch (level) {
      case BudgetAlertLevel.over:
        return cs.error;
      case BudgetAlertLevel.warning:
        return cs.tertiary;
      case BudgetAlertLevel.caution:
        return cs.secondary;
      case BudgetAlertLevel.good:
        return cs.primary;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetAsync = ref.watch(budgetProvider);
    final overallStatusAsync = ref.watch(overallBudgetStatusProvider);
    final settingsAsync = ref.watch(settingsProvider);
    final currency = settingsAsync.valueOrNull?.currency ?? Currency.USD;
    final formatter = NumberFormat.currency(symbol: currency.name, decimalDigits: 2);
    final theme = Theme.of(context);

    return budgetAsync.when(
      data: (budget) {
        if (budget == null) {
          return const SizedBox.shrink();
        }

        return overallStatusAsync.when(
          data: (status) {
            final highlightColor = _levelColor(context, status.alertLevel);
            final negativeColor = theme.colorScheme.error;

            return Card(
              child: InkWell(
                onTap: () => context.push('/budget-overview'),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: highlightColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.account_balance_wallet_outlined,
                                  color: highlightColor,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Monthly Budget',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: highlightColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${status.percentageUsed.toStringAsFixed(0)}%',
                              style: TextStyle(
                                color: highlightColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      LinearProgressIndicator(
                        value: (status.percentageUsed / 100).clamp(0.0, 1.0),
                        minHeight: 8,
                        backgroundColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
                        valueColor: AlwaysStoppedAnimation<Color>(highlightColor),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Spent',
                                style: theme.textTheme.bodySmall,
                              ),
                              Text(
                                formatter.format(status.spent),
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Remaining',
                                style: theme.textTheme.bodySmall,
                              ),
                              Text(
                                formatter.format(status.remaining),
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: status.remaining < 0
                                      ? negativeColor
                                      : highlightColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
          loading: () => const Card(child: Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator()),
          )),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
