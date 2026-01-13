import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';

class CategoryData {
  final String name;
  final String emoji;
  final double amount;
  final Color color;

  const CategoryData({
    required this.name,
    required this.emoji,
    required this.amount,
    required this.color,
  });
}

class TopCategoriesWidget extends StatelessWidget {
  final List<CategoryData> categories;
  final String period;

  const TopCategoriesWidget({
    super.key,
    required this.categories,
    this.period = 'This month',
  });

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    final colorScheme = Theme.of(context).colorScheme;
    final displayCategories = categories.take(3).toList();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: colorScheme.outlineVariant.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top Categories',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            if (displayCategories.isEmpty) ...[
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.category_outlined,
                        size: 48,
                        color: colorScheme.outlineVariant,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No categories yet',
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              ...displayCategories.map((category) {
                final index = displayCategories.indexOf(category);
                return Padding(
                  padding: EdgeInsets.only(bottom: index < displayCategories.length - 1 ? 12.0 : 0),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: category.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            category.emoji,
                            style: const TextStyle(fontSize: 18),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              category.name,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              formatter.format(category.amount),
                              style: TextStyle(
                                fontSize: 12,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: category.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ).animate(delay: Duration(milliseconds: index * 100)).fadeIn().slideX(begin: 0.1);
              }),
            ],
          ],
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }
}
