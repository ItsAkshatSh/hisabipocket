import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hisabi/core/utils/theme_extensions.dart';
import 'package:hisabi/core/models/category_model.dart';
import 'package:hisabi/features/insights/models/insights_models.dart';
import 'package:intl/intl.dart';

class BudgetPlannerCard extends StatefulWidget {
  final InsightsData insights;
  
  const BudgetPlannerCard({super.key, required this.insights});

  @override
  State<BudgetPlannerCard> createState() => _BudgetPlannerCardState();
}

class _BudgetPlannerCardState extends State<BudgetPlannerCard> {
  bool _showAllCategories = false;

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(
      symbol: widget.insights.currency.name,
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
                    color: context.borderColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.account_balance_wallet_outlined,
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
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Edit Budgets',
                  onPressed: () => _navigateToBudgetSetup(context),
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
                  formatter.format(widget.insights.estimatedIncome),
                ),
                _buildStatRow(
                  context,
                  'Current Spending',
                  formatter.format(widget.insights.monthlySpending),
                ),
                _buildStatRow(
                  context,
                  'Savings Rate',
                  '${widget.insights.savingsRate.toStringAsFixed(1)}%',
                  isHighlight: true,
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Suggested Budgets
            if (widget.insights.suggestedBudgets != null) ...[
              Text(
                'Suggested Budgets by Category',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: context.onSurfaceColor,
                ),
              ),
              const SizedBox(height: 12),
              _buildCategoryBudgets(context, formatter),
            ],
            
            // Recommendations
            if (widget.insights.recommendations != null && widget.insights.recommendations!.isNotEmpty) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.borderColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: context.borderColor.withOpacity(0.3),
                    width: 1,
                  ),
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
                          'AI Recommendations',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: context.onSurfaceColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...widget.insights.recommendations!.map((rec) => Padding(
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

  Widget _buildCategoryBudgets(BuildContext context, NumberFormat formatter) {
    final budgets = widget.insights.suggestedBudgets!;
    final budgetEntries = budgets.entries.toList();
    final visibleCount = _showAllCategories ? budgetEntries.length : 3;
    final visibleEntries = budgetEntries.take(visibleCount).toList();
    final hasMore = budgetEntries.length > visibleCount;

    return Column(
      children: [
        ...visibleEntries.map((entry) => _buildCategoryBudgetItem(context, formatter, entry)),
        if (hasMore)
          InkWell(
            onTap: () {
              setState(() {
                _showAllCategories = !_showAllCategories;
              });
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _showAllCategories ? 'Show Less' : 'Show More',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: context.primaryColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _showAllCategories ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: context.primaryColor,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCategoryBudgetItem(BuildContext context, NumberFormat formatter, MapEntry<String, double> entry) {
    final category = ExpenseCategory.values.firstWhere(
      (c) => c.name == entry.key,
      orElse: () => ExpenseCategory.other,
    );
    final categoryInfo = CategoryInfo.getInfo(category);
    final currentSpending = widget.insights.categorySpending[category] ?? 0.0;
    final budget = entry.value;
    final percentage = budget > 0 ? (currentSpending / budget * 100) : 0;
    final progressValue = percentage / 100;
    
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
            value: progressValue > 1.0 ? 1.0 : (progressValue < 0.0 ? 0.0 : progressValue),
            backgroundColor: context.borderColor.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(
              percentage > 100
                  ? context.errorColor
                  : context.onSurfaceColor,
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
  }

  void _navigateToBudgetSetup(BuildContext context) {
    final budgets = widget.insights.suggestedBudgets;
    if (budgets != null) {
      final categoryBudgets = <ExpenseCategory, double>{};
      for (final entry in budgets.entries) {
        final category = ExpenseCategory.values.firstWhere(
          (c) => c.name == entry.key,
          orElse: () => ExpenseCategory.other,
        );
        categoryBudgets[category] = entry.value;
      }
      context.push('/budget-setup', extra: categoryBudgets);
    } else {
      context.push('/budget-setup');
    }
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
              color: context.onSurfaceColor,
            ),
          ),
        ],
      ),
    );
  }
}
