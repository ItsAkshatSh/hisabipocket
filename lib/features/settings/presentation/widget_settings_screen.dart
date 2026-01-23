import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisabi/features/settings/providers/settings_provider.dart';
import 'package:hisabi/features/settings/presentation/widgets/widget_preview.dart';

class WidgetSettingsScreen extends ConsumerStatefulWidget {
  const WidgetSettingsScreen({super.key});

  @override
  ConsumerState<WidgetSettingsScreen> createState() => _WidgetSettingsScreenState();
}

class _WidgetSettingsScreenState extends ConsumerState<WidgetSettingsScreen> {
  Set<WidgetStat>? _selectedStats;

  @override
  void initState() {
    super.initState();
  }

  String _getStatLabel(WidgetStat stat) {
    switch (stat) {
      case WidgetStat.totalThisMonth:
        return 'Total This Month';
      case WidgetStat.topStore:
        return 'Top Store';
      case WidgetStat.receiptsCount:
        return 'Receipts Count';
      case WidgetStat.averagePerReceipt:
        return 'Average Per Receipt';
      case WidgetStat.daysWithExpenses:
        return 'Days With Expenses';
      case WidgetStat.totalItems:
        return 'Total Items';
      case WidgetStat.expenseTrend:
        return 'Expense Trend';
      case WidgetStat.savingsGoal:
        return 'Savings Goal';
    }
  }

  IconData _getStatIcon(WidgetStat stat) {
    switch (stat) {
      case WidgetStat.totalThisMonth:
        return Icons.account_balance_wallet_rounded;
      case WidgetStat.topStore:
        return Icons.store_rounded;
      case WidgetStat.receiptsCount:
        return Icons.receipt_long_rounded;
      case WidgetStat.averagePerReceipt:
        return Icons.analytics_rounded;
      case WidgetStat.daysWithExpenses:
        return Icons.calendar_today_rounded;
      case WidgetStat.totalItems:
        return Icons.shopping_cart_rounded;
      case WidgetStat.expenseTrend:
        return Icons.trending_up_rounded;
      case WidgetStat.savingsGoal:
        return Icons.savings_rounded;
    }
  }

  void _toggleStat(WidgetStat stat) {
    setState(() {
      _selectedStats ??= Set.from(ref.read(settingsProvider).valueOrNull?.widgetSettings.enabledStats ?? {});
      if (_selectedStats!.contains(stat)) {
        if (_selectedStats!.length > 1) {
          _selectedStats!.remove(stat);
          _saveSettings();
        }
      } else {
        _selectedStats!.add(stat);
        _saveSettings();
      }
    });
  }

  void _saveSettings() {
    if (_selectedStats != null && _selectedStats!.isNotEmpty) {
      final newWidgetSettings = WidgetSettings(enabledStats: _selectedStats!);
      ref.read(settingsProvider.notifier).setWidgetSettings(newWidgetSettings);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);
    final currency = settingsAsync.valueOrNull?.currency ?? Currency.USD;
    
    if (_selectedStats == null && settingsAsync.valueOrNull != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _selectedStats = Set.from(settingsAsync.valueOrNull!.widgetSettings.enabledStats);
        });
      });
    }
    
    final currentStats = _selectedStats ?? settingsAsync.valueOrNull?.widgetSettings.enabledStats ?? {};

    return Scaffold(
      appBar: AppBar(
        title: const Text('Widget Settings'),
      ),
      body: settingsAsync.when(
        data: (settings) => CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(20.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 8),
                  Text(
                    'Preview',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).colorScheme.primary,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  WidgetPreview(
                    enabledStats: currentStats,
                    currency: currency,
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Select Stats',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).colorScheme.primary,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      children: WidgetStat.values.map((stat) {
                        final isSelected = currentStats.contains(stat);
                        return Column(
                          children: [
                            ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  _getStatIcon(stat),
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 22,
                                ),
                              ),
                              title: Text(
                                _getStatLabel(stat),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                ),
                              ),
                              trailing: Switch(
                                value: isSelected,
                                onChanged: (_) => _toggleStat(stat),
                              ),
                            ),
                            if (stat != WidgetStat.values.last)
                              const Divider(height: 1),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (currentStats.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Theme.of(context).colorScheme.error,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'At least one stat must be enabled',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onErrorContainer,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 120),
                ]),
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error loading settings: $err')),
      ),
    );
  }
}

