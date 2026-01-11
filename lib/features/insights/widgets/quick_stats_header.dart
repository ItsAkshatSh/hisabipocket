import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisabi/core/utils/theme_extensions.dart';
import 'package:hisabi/features/insights/models/insights_models.dart';
import 'package:hisabi/core/models/category_model.dart';
import 'package:intl/intl.dart';

class QuickStatsHeader extends ConsumerWidget {
  final InsightsData insights;
  
  const QuickStatsHeader({super.key, required this.insights});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formatter = NumberFormat.currency(
      symbol: insights.currency.name,
      decimalDigits: 2,
    );
    
    final topCategory = insights.categorySpending.entries.isEmpty
        ? null
        : insights.categorySpending.entries.reduce(
            (a, b) => a.value > b.value ? a : b,
          );
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildStatItem(
                context,
                'Total Spending',
                formatter.format(insights.monthlySpending),
                Icons.account_balance_wallet_outlined,
              ),
            ),
            Container(
              width: 1,
              height: 40,
              color: context.borderColor.withOpacity(0.3),
            ),
            Expanded(
              child: _buildStatItem(
                context,
                'Categories',
                insights.categorySpending.length.toString(),
                Icons.category_outlined,
              ),
            ),
            Container(
              width: 1,
              height: 40,
              color: context.borderColor.withOpacity(0.3),
            ),
            Expanded(
              child: _buildStatItem(
                context,
                'Savings Rate',
                '${insights.savingsRate.toStringAsFixed(1)}%',
                Icons.trending_up_outlined,
              ),
            ),
            if (topCategory != null) ...[
              Container(
                width: 1,
                height: 40,
                color: context.borderColor.withOpacity(0.3),
              ),
              Expanded(
                child: _buildStatItem(
                  context,
                  'Top Category',
                  CategoryInfo.getInfo(topCategory.key).emoji,
                  Icons.star_outline,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 24,
          color: context.onSurfaceMutedColor,
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: context.onSurfaceColor,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: context.onSurfaceMutedColor,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
