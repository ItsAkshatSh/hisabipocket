import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisabi/core/utils/theme_extensions.dart';
import 'package:hisabi/features/insights/models/spending_alert.dart';
import 'package:hisabi/core/models/category_model.dart';
import 'package:intl/intl.dart';

class SpendingAlertsCard extends ConsumerWidget {
  final List<SpendingAlert> alerts;
  
  const SpendingAlertsCard({super.key, required this.alerts});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (alerts.isEmpty) {
      return const SizedBox.shrink();
    }
    
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
                    color: _getSeverityColor(context, AlertSeverity.warning).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: _getSeverityColor(context, AlertSeverity.warning),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Spending Alerts',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: context.onSurfaceColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${alerts.length} alert${alerts.length > 1 ? 's' : ''} detected',
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
            ...alerts.take(5).map((alert) => _buildAlertItem(context, alert)),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAlertItem(BuildContext context, SpendingAlert alert) {
    final severityColor = _getSeverityColor(context, alert.severity);
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: severityColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: severityColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getAlertIcon(alert.type),
                size: 20,
                color: severityColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  alert.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: context.onSurfaceColor,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: severityColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  alert.severity.name.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: severityColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            alert.message,
            style: TextStyle(
              fontSize: 14,
              color: context.onSurfaceColor,
              height: 1.4,
            ),
          ),
          if (alert.amount != null) ...[
            const SizedBox(height: 8),
            Text(
              'Amount: ${formatter.format(alert.amount)}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: context.onSurfaceMutedColor,
              ),
            ),
          ],
          if (alert.actionableSteps.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...alert.actionableSteps.map((step) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '• ',
                    style: TextStyle(
                      color: severityColor,
                      fontSize: 14,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      step,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.onSurfaceMutedColor,
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }
  
  Color _getSeverityColor(BuildContext context, AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.critical:
        return context.errorColor;
      case AlertSeverity.warning:
        return Colors.orange;
      case AlertSeverity.info:
        return context.primaryColor;
    }
  }
  
  IconData _getAlertIcon(AlertType type) {
    switch (type) {
      case AlertType.budgetExceeded:
        return Icons.account_balance_wallet;
      case AlertType.unusualSpending:
        return Icons.attach_money;
      case AlertType.recurringExpenseDetected:
        return Icons.repeat;
      case AlertType.savingsOpportunity:
        return Icons.savings;
      case AlertType.trendAlert:
        return Icons.trending_up;
      case AlertType.categorySpike:
        return Icons.show_chart;
    }
  }
}
