import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:hisabi/core/utils/theme_extensions.dart';
import 'package:hisabi/features/insights/models/period_comparison.dart';
import 'package:hisabi/core/models/category_model.dart';
import 'package:hisabi/features/settings/providers/settings_provider.dart';

class PeriodComparisonCard extends ConsumerWidget {
  final PeriodComparison comparison;

  const PeriodComparisonCard({super.key, required this.comparison});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    final currency = settingsAsync.valueOrNull?.currency ?? Currency.USD;

    final formatter =
        NumberFormat.currency(symbol: currency.name, decimalDigits: 2);
    final isPositive = comparison.changePercent > 0;
    final trendColor = isPositive
        ? context.errorColor
        : (comparison.changePercent < 0
            ? Colors.green
            : context.onSurfaceColor);

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
                    color: context.borderColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.compare_arrows,
                    color: context.onSurfaceColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Month Comparison',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: context.onSurfaceColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'This month vs last month',
                        style: TextStyle(
                          fontSize: 14,
                          color: context.onSurfaceMutedColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Overall comparison (original layout)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Expanded(
                  child: _buildComparisonItem(
                    context,
                    'This Month',
                    formatter.format(comparison.currentAmount),
                    null,
                  ),
                ),
                Icon(
                  isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                  color: trendColor,
                  size: 32,
                ),
                Expanded(
                  child: _buildComparisonItem(
                    context,
                    'Last Month',
                    formatter.format(comparison.previousAmount),
                    null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Change indicator
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: trendColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: trendColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isPositive ? Icons.trending_up : Icons.trending_down,
                    color: trendColor,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${isPositive ? '+' : ''}${comparison.changePercent.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: trendColor,
                    ),
                  ),
                ],
              ),
            ),

            // Category comparisons
            if (comparison.categoryComparisons.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'Category Breakdown',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: context.onSurfaceColor,
                ),
              ),
              const SizedBox(height: 12),
              ...comparison.categoryComparisons.values
                  .where((c) => c.isSignificant)
                  .take(5)
                  .map((categoryComp) => _buildCategoryComparison(
                      context, categoryComp, formatter)),
            ],

            // Insights
            if (comparison.insights.isNotEmpty) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.borderColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          color: context.onSurfaceColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Key Insights',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: context.onSurfaceColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...comparison.insights.take(3).map(
                          (insight) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '• ',
                                  style: TextStyle(
                                    color: context.onSurfaceColor,
                                    fontSize: 16,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    insight,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: context.onSurfaceColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonItem(
    BuildContext context,
    String label,
    String value,
    String? subtitle,
  ) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: context.onSurfaceMutedColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: context.onSurfaceColor,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: context.onSurfaceMutedColor,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCategoryComparison(
    BuildContext context,
    CategoryComparison comp,
    NumberFormat formatter,
  ) {
    final isPositive = comp.changePercent > 0;
    final trendColor = isPositive
        ? context.errorColor
        : (comp.changePercent < 0 ? Colors.green : context.onSurfaceColor);
    final categoryInfo = CategoryInfo.getInfo(comp.category);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(
            categoryInfo.emoji,
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  categoryInfo.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: context.onSurfaceColor,
                  ),
                ),
                Text(
                  comp.insight,
                  style: TextStyle(
                    fontSize: 12,
                    color: context.onSurfaceMutedColor,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatter.format(comp.current),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: context.onSurfaceColor,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                    size: 14,
                    color: trendColor,
                  ),
                  Text(
                    '${comp.changePercent.abs().toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 12,
                      color: trendColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
