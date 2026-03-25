import 'package:flutter/material.dart';
import 'package:hisabi/core/utils/theme_extensions.dart';
import 'package:hisabi/core/models/category_model.dart';
import 'package:hisabi/features/insights/models/insights_models.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

class PremiumCategoryBreakdown extends StatelessWidget {
  final InsightsData insights;

  const PremiumCategoryBreakdown({super.key, required this.insights});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final formatter = NumberFormat.currency(
      symbol: insights.currency.name,
      decimalDigits: 0,
    );

    final sortedCategories = insights.categorySpending.entries
        .where((e) => e.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sortedCategories.isEmpty) {
      return _buildEmptyState(context);
    }

    final topCategories = sortedCategories.take(5).toList();
    final maxValue = topCategories.first.value;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: cs.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mini bar chart at top
            _buildMiniChart(context, topCategories, maxValue),
            const Divider(height: 1),
            // Category list
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: topCategories.asMap().entries.map((entry) {
                  final index = entry.key;
                  final category = entry.value.key;
                  final amount = entry.value.value;
                  final percentage = insights.monthlySpending > 0
                      ? (amount / insights.monthlySpending * 100).toDouble()
                      : 0.0;
                  final categoryInfo = CategoryInfo.getInfo(category);
                  final isLast = index == topCategories.length - 1;

                  return Padding(
                    padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                    child: _buildCategoryRow(
                      context,
                      categoryInfo.emoji,
                      categoryInfo.name,
                      amount,
                      percentage,
                      formatter,
                      _getCategoryColor(index, cs),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniChart(BuildContext context, List<MapEntry<ExpenseCategory, double>> categories, double maxValue) {
    final cs = Theme.of(context).colorScheme;
    final total = categories.fold<double>(0, (sum, c) => sum + c.value);

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: categories.asMap().entries.map((entry) {
          final index = entry.key;
          final amount = entry.value.value;
          final ratio = total > 0 ? amount / total : 0;

          return Expanded(
            flex: math.max((ratio * 100).round(), 1),
            child: Container(
              margin: EdgeInsets.only(
                left: index == 0 ? 0 : 4,
              ),
              decoration: BoxDecoration(
                color: _getCategoryColor(index, cs),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCategoryRow(
    BuildContext context,
    String emoji,
    String name,
    double amount,
    double percentage,
    NumberFormat formatter,
    Color color,
  ) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              emoji,
              style: const TextStyle(fontSize: 20),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: (percentage / 100).clamp(0.0, 1.0),
                  minHeight: 4,
                  backgroundColor: cs.outlineVariant.withOpacity(0.3),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              formatter.format(amount),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            Text(
              '${percentage.toStringAsFixed(0)}%',
              style: theme.textTheme.labelSmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: cs.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.pie_chart_outline,
              size: 40,
              color: cs.onSurfaceVariant.withOpacity(0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'No spending data yet',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(int index, ColorScheme cs) {
    final colors = [
      cs.primary,
      cs.tertiary,
      cs.secondary,
      cs.error,
      Colors.orange,
    ];
    return colors[index % colors.length];
  }
}
