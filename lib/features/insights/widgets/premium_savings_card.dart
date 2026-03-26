import 'package:flutter/material.dart';
import 'package:hisabi/features/insights/models/insights_models.dart';
import 'package:intl/intl.dart';

class PremiumSavingsCard extends StatelessWidget {
  final InsightsData insights;

  const PremiumSavingsCard({super.key, required this.insights});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final formatter = NumberFormat.currency(
      symbol: insights.currency.name,
      decimalDigits: 0,
    );

    final savingsRate = insights.savingsRate;
    final isPositive = savingsRate >= 0;
    final savingsAmount = insights.estimatedIncome - insights.monthlySpending;

    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: cs.outlineVariant.withOpacity(0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isPositive
                      ? [
                          cs.tertiaryContainer,
                          cs.tertiaryContainer.withOpacity(0.8),
                        ]
                      : [
                          cs.errorContainer,
                          cs.errorContainer.withOpacity(0.8),
                        ],
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (isPositive ? cs.onTertiaryContainer : cs.onErrorContainer)
                          .withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isPositive ? Icons.savings_rounded : Icons.warning_rounded,
                      color: isPositive ? cs.onTertiaryContainer : cs.onErrorContainer,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isPositive ? 'Savings Rate' : 'Over Budget',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: (isPositive ? cs.onTertiaryContainer : cs.onErrorContainer)
                                .withOpacity(0.8),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              '${savingsRate.abs().toStringAsFixed(1)}%',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: isPositive ? cs.onTertiaryContainer : cs.onErrorContainer,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: (isPositive ? cs.onTertiaryContainer : cs.onErrorContainer)
                                    .withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                isPositive ? 'On Track' : 'Alert',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: isPositive ? cs.onTertiaryContainer : cs.onErrorContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  _buildStat(
                    context,
                    'Monthly Income',
                    formatter.format(insights.estimatedIncome),
                    Icons.account_balance_wallet_outlined,
                  ),
                  const SizedBox(width: 16),
                  _buildStat(
                    context,
                    isPositive ? 'Saved' : 'Overspent',
                    formatter.format(savingsAmount.abs()),
                    isPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                    isAlert: !isPositive,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStat(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    bool isAlert = false,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isAlert ? cs.errorContainer.withOpacity(0.3) : cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: isAlert ? cs.error : cs.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isAlert ? cs.error : cs.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: isAlert ? cs.error : cs.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
