import 'package:flutter/material.dart';
import 'package:hisabi/core/utils/theme_extensions.dart';
import 'package:hisabi/core/models/category_model.dart';
import 'package:hisabi/features/insights/models/insights_models.dart';
import 'package:intl/intl.dart';

class SpendingAnalysisCard extends StatefulWidget {
  final InsightsData insights;
  
  const SpendingAnalysisCard({super.key, required this.insights});

  @override
  State<SpendingAnalysisCard> createState() => _SpendingAnalysisCardState();
}

class _SpendingAnalysisCardState extends State<SpendingAnalysisCard> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(
      symbol: widget.insights.currency.name,
      decimalDigits: 2,
    );
    
    // Sort categories by spending (descending)
    final sortedCategories = widget.insights.categorySpending.entries
        .where((e) => e.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final displayedCategories = _showAll 
        ? sortedCategories 
        : sortedCategories.take(3).toList();

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
                    Icons.pie_chart_outline,
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
            else ...[
              ...displayedCategories.map((entry) {
                final category = entry.key;
                final amount = entry.value;
                final percentage = widget.insights.monthlySpending > 0
                    ? (amount / widget.insights.monthlySpending * 100)
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
                          value: (percentage / 100).clamp(0.0, 1.0),
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
              
              if (sortedCategories.length > 3)
                Center(
                  child: TextButton(
                    onPressed: () => setState(() => _showAll = !_showAll),
                    child: Text(_showAll ? 'Show Less' : 'Show More'),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
