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
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: context.borderColor.withOpacity(0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
        child: Row(
          children: [
            _buildFlexibleStat(
              context,
              'Spending',
              formatter.format(insights.monthlySpending),
              Icons.account_balance_wallet_outlined,
            ),
            _buildDivider(context),
            _buildFlexibleStat(
              context,
              'Categories',
              insights.categorySpending.length.toString(),
              Icons.category_outlined,
            ),
            _buildDivider(context),
            _buildFlexibleStat(
              context,
              'Savings',
              '${insights.savingsRate.toStringAsFixed(1)}%',
              Icons.trending_up_outlined,
            ),
            if (topCategory != null) ...[
              _buildDivider(context),
              _buildFlexibleStat(
                context,
                'Top',
                CategoryInfo.getInfo(topCategory.key).emoji,
                Icons.star_outline,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFlexibleStat(BuildContext context, String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: context.onSurfaceMutedColor),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: context.onSurfaceColor,
              ),
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: context.onSurfaceMutedColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Container(
      width: 1,
      height: 30,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: context.borderColor.withOpacity(0.3),
    );
  }
}
