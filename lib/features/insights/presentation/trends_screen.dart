import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisabi/features/insights/providers/trends_provider.dart';
import 'package:hisabi/features/settings/providers/settings_provider.dart';
import 'package:intl/intl.dart';
import 'package:hisabi/core/models/category_model.dart';

class TrendsScreen extends ConsumerWidget {
  const TrendsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trendsAsync = ref.watch(trendsProvider);
    final settingsAsync = ref.watch(settingsProvider);
    final currency = settingsAsync.valueOrNull?.currency ?? Currency.USD;
    final formatter = NumberFormat.currency(symbol: currency.name, decimalDigits: 2);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense Trends'),
      ),
      body: trendsAsync.when(
        data: (analysis) {
          if (analysis.trends.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.trending_up_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No trends available',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add more receipts to see spending trends',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Text(
                          'Average Monthly Spending',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          formatter.format(analysis.averageMonthly),
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (analysis.monthOverMonthChange != null) ...[
                  _buildChangeCard(
                    context,
                    'Month over Month',
                    analysis.monthOverMonthChange!,
                    formatter,
                  ),
                  const SizedBox(height: 16),
                ],
                if (analysis.yearOverYearChange != null) ...[
                  _buildChangeCard(
                    context,
                    'Year over Year',
                    analysis.yearOverYearChange!,
                    formatter,
                  ),
                  const SizedBox(height: 16),
                ],
                if (analysis.topCategory != null && analysis.topCategorySpending != null) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Top Spending Category',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Text(
                                CategoryInfo.getInfo(analysis.topCategory!).emoji,
                                style: const TextStyle(fontSize: 32),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      CategoryInfo.getInfo(analysis.topCategory!).name,
                                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      formatter.format(analysis.topCategorySpending!),
                                      style: Theme.of(context).textTheme.bodyLarge,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                Text(
                  'Recent Trends',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...analysis.trends.take(20).map((trend) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: trend.category != null
                        ? Text(
                            CategoryInfo.getInfo(trend.category!).emoji,
                            style: const TextStyle(fontSize: 24),
                          )
                        : const Icon(Icons.receipt),
                    title: Text(DateFormat.yMMMd().format(trend.date)),
                    subtitle: trend.category != null
                        ? Text(CategoryInfo.getInfo(trend.category!).name)
                        : null,
                    trailing: Text(
                      formatter.format(trend.amount),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                )),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildChangeCard(
    BuildContext context,
    String label,
    double changePercent,
    NumberFormat formatter,
  ) {
    final isPositive = changePercent > 0;
    final color = isPositive ? Colors.red : Colors.green;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Row(
              children: [
                Icon(
                  isPositive ? Icons.trending_up : Icons.trending_down,
                  color: color,
                ),
                const SizedBox(width: 8),
                Text(
                  '${isPositive ? '+' : ''}${changePercent.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

