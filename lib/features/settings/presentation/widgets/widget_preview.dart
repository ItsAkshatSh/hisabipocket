import 'package:flutter/material.dart';
import 'package:hisabi/core/utils/theme_extensions.dart';
import 'package:hisabi/features/settings/providers/settings_provider.dart';
import 'package:intl/intl.dart';

class WidgetPreview extends StatelessWidget {
  final Set<WidgetStat> enabledStats;
  final Currency currency;

  const WidgetPreview({
    super.key,
    required this.enabledStats,
    required this.currency,
  });

  String _formatCurrency(double value) {
    final formatted = NumberFormat('#,##0.00').format(value);
    return '${currency.name} $formatted';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF212834), // Dark widget background
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.borderColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'This month',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          if (enabledStats.contains(WidgetStat.totalThisMonth)) ...[
            const SizedBox(height: 4),
            Text(
              _formatCurrency(1234.56),
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
          if (enabledStats.contains(WidgetStat.topStore)) ...[
            const SizedBox(height: 2),
            Text(
              'Top: Sample Store',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
          if (enabledStats.contains(WidgetStat.receiptsCount)) ...[
            const SizedBox(height: 4),
            Text(
              'Receipts: 12',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
          if (enabledStats.contains(WidgetStat.averagePerReceipt)) ...[
            const SizedBox(height: 4),
            Text(
              'Avg: ${_formatCurrency(102.88)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
          if (enabledStats.contains(WidgetStat.daysWithExpenses)) ...[
            const SizedBox(height: 4),
            Text(
              'Days: 8',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
          if (enabledStats.contains(WidgetStat.totalItems)) ...[
            const SizedBox(height: 4),
            Text(
              'Items: 45',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.mic,
                  size: 20,
                  color: Colors.white.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

