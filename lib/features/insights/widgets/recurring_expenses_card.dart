import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisabi/core/utils/theme_extensions.dart';
import 'package:hisabi/features/insights/models/recurring_expense.dart';
import 'package:hisabi/core/models/category_model.dart';
import 'package:intl/intl.dart';

class RecurringExpensesCard extends ConsumerWidget {
  final List<RecurringExpense> expenses;
  
  const RecurringExpensesCard({super.key, required this.expenses});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (expenses.isEmpty) {
      return const SizedBox.shrink();
    }
    
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final totalMonthly = expenses.fold<double>(0.0, (sum, e) => sum + e.monthlyCost);
    final totalYearly = expenses.fold<double>(
      0.0,
      (sum, e) => sum + (e.estimatedYearlyCost ?? 0),
    );
    
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
                    Icons.repeat,
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
                        'Recurring Expenses',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: context.onSurfaceColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${expenses.length} subscription${expenses.length > 1 ? 's' : ''} detected',
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
            
            // Summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.borderColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(
                        formatter.format(totalMonthly),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: context.onSurfaceColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Monthly',
                        style: TextStyle(
                          fontSize: 12,
                          color: context.onSurfaceMutedColor,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 1,
                    height: 40,
                    color: context.borderColor.withOpacity(0.3),
                  ),
                  Column(
                    children: [
                      Text(
                        formatter.format(totalYearly),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: context.onSurfaceColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Yearly',
                        style: TextStyle(
                          fontSize: 12,
                          color: context.onSurfaceMutedColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // List of expenses
            ...expenses.take(5).map((expense) => _buildExpenseItem(context, expense, formatter)),
          ],
        ),
      ),
    );
  }
  
  Widget _buildExpenseItem(
    BuildContext context,
    RecurringExpense expense,
    NumberFormat formatter,
  ) {
    final categoryInfo = CategoryInfo.getInfo(expense.category);
    final nextDueText = _formatNextDue(expense.nextDue);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.borderColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.borderColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                categoryInfo.emoji,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      expense.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: context.onSurfaceColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatFrequency(expense.frequency),
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
                    formatter.format(expense.amount),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: context.onSurfaceColor,
                    ),
                  ),
                  if (expense.estimatedYearlyCost != null)
                    Text(
                      '${formatter.format(expense.estimatedYearlyCost)}/yr',
                      style: TextStyle(
                        fontSize: 11,
                        color: context.onSurfaceMutedColor,
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 14,
                color: context.onSurfaceMutedColor,
              ),
              const SizedBox(width: 4),
              Text(
                'Next: $nextDueText',
                style: TextStyle(
                  fontSize: 12,
                  color: context.onSurfaceMutedColor,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getConfidenceColor(context, expense.confidence).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${(expense.confidence * 100).toStringAsFixed(0)}% confidence',
                  style: TextStyle(
                    fontSize: 10,
                    color: _getConfidenceColor(context, expense.confidence),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  String _formatFrequency(RecurrenceType frequency) {
    switch (frequency) {
      case RecurrenceType.weekly:
        return 'Weekly';
      case RecurrenceType.biweekly:
        return 'Bi-weekly';
      case RecurrenceType.monthly:
        return 'Monthly';
      case RecurrenceType.quarterly:
        return 'Quarterly';
      case RecurrenceType.yearly:
        return 'Yearly';
      case RecurrenceType.irregular:
        return 'Irregular';
    }
  }
  
  String _formatNextDue(DateTime nextDue) {
    final now = DateTime.now();
    final difference = nextDue.difference(now);
    
    if (difference.inDays < 0) {
      return 'Overdue';
    } else if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Tomorrow';
    } else if (difference.inDays < 7) {
      return 'In ${difference.inDays} days';
    } else if (difference.inDays < 30) {
      return 'In ${(difference.inDays / 7).floor()} weeks';
    } else {
      return DateFormat('MMM d').format(nextDue);
    }
  }
  
  Color _getConfidenceColor(BuildContext context, double confidence) {
    if (confidence >= 0.8) {
      return Colors.green;
    } else if (confidence >= 0.6) {
      return Colors.orange;
    } else {
      return context.onSurfaceMutedColor;
    }
  }
}
