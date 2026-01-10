import 'package:flutter/material.dart';
import 'package:hisabi/core/utils/theme_extensions.dart';
import 'package:hisabi/core/models/category_model.dart';
import 'package:hisabi/features/insights/models/insights_models.dart';
import 'package:intl/intl.dart';

class SpendingAnalysisCard extends StatelessWidget {
  final InsightsData insights;
  
  const SpendingAnalysisCard({super.key, required this.insights});

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(
      symbol: insights.currency.name,
      decimalDigits: 2,
    );
    
    // Sort categories by spending
    final sortedCategories = insights.categorySpending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
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
                    Icons.pie_chart_outlined,
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
                        'Spending Analysis',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: context.onSurfaceColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Breakdown by category',
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
            
            if (sortedCategories.isEmpty)
              Text(
                'No spending data available',
                style: TextStyle(
                  fontSize: 14,
                  color: context.onSurfaceMutedColor,
                  fontStyle: FontStyle.italic,
                ),
              )
            else
              ...sortedCategories.take(8).map((entry) {
                final category = entry.key;
                final amount = entry.value;
                final percentage = insights.monthlySpending > 0
                    ? (amount / insights.monthlySpending * 100)
                    : 0;
                final categoryInfo = CategoryInfo.getInfo(category);
                
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
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
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                formatter.format(amount),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: context.onSurfaceColor,
                                ),
                              ),
                              Text(
                                '${percentage.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: context.onSurfaceMutedColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: percentage / 100,
                          minHeight: 6,
                          backgroundColor: context.borderColor.withOpacity(0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            context.onSurfaceColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

