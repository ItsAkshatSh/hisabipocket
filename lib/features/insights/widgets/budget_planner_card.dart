import 'package:flutter/material.dart';
import 'package:hisabi/core/utils/theme_extensions.dart';
import 'package:hisabi/core/models/category_model.dart';
import 'package:hisabi/features/insights/models/insights_models.dart';
import 'package:intl/intl.dart';

class BudgetPlannerCard extends StatelessWidget {
  final InsightsData insights;
  
  const BudgetPlannerCard({super.key, required this.insights});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(
      symbol: insights.currency.name,
      decimalDigits: 2,
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
                    color: context.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.account_balance_wallet_outlined,
                    color: context.primaryColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Budget Planner',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: context.onSurfaceColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'AI-powered budget recommendations',
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
            
            // Monthly Overview
            _buildSection(
              context,
              'Monthly Overview',
              [
                _buildStatRow(
                  context,
                  'Estimated Income',
                  formatter.format(insights.estimatedIncome),
                ),
                _buildStatRow(
                  context,
                  'Current Spending',
                  formatter.format(insights.monthlySpending),
                ),
                _buildStatRow(
                  context,
                  'Savings Rate',
                  '${insights.savingsRate.toStringAsFixed(1)}%',
                  isHighlight: true,
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Suggested Budgets
            if (insights.suggestedBudgets != null) ...[
              Text(
                'Suggested Budgets by Category',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: context.onSurfaceColor,
                ),
              ),
              const SizedBox(height: 12),
              ...insights.suggestedBudgets!.entries.take(5).map((entry) {
                final category = ExpenseCategory.values.firstWhere(
                  (c) => c.name == entry.key,
                  orElse: () => ExpenseCategory.other,
                );
                final categoryInfo = CategoryInfo.getInfo(category);
                final currentSpending = insights.categorySpending[category] ?? 0.0;
                final budget = entry.value;
                final percentage = budget > 0 ? (currentSpending / budget * 100) : 0;
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                categoryInfo.emoji,
                                style: const TextStyle(fontSize: 20),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                categoryInfo.name,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: context.onSurfaceColor,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            formatter.format(budget),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: context.onSurfaceColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: percentage > 1 ? 1 : percentage,
                        backgroundColor: context.borderColor.withOpacity(0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          percentage > 1
                              ? context.errorColor
                              : context.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Spent: ${formatter.format(currentSpending)} (${percentage.toStringAsFixed(0)}%)',
                        style: TextStyle(
                          fontSize: 12,
                          color: context.onSurfaceMutedColor,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
            
            // Recommendations
            if (insights.recommendations != null && insights.recommendations!.isNotEmpty) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          color: context.primaryColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'AI Recommendations',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: context.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...insights.recommendations!.map((rec) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '• ',
                            style: TextStyle(
                              color: context.primaryColor,
                              fontSize: 16,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              rec,
                              style: TextStyle(
                                fontSize: 14,
                                color: context.onSurfaceColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: context.onSurfaceColor,
          ),
        ),
        const SizedBox(height: 12),
        ...children,
      ],
    );
  }
  
  Widget _buildStatRow(
    BuildContext context,
    String label,
    String value, {
    bool isHighlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: context.onSurfaceMutedColor,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w500,
              color: isHighlight
                  ? context.primaryColor
                  : context.onSurfaceColor,
            ),
          ),
        ],
      ),
    );
  }
}

