import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisabi/core/models/category_model.dart';
import 'package:hisabi/features/budgets/models/budget_model.dart';
import 'package:hisabi/features/budgets/providers/budget_provider.dart';
import 'package:hisabi/features/financial_profile/providers/financial_profile_provider.dart';
import 'package:hisabi/features/settings/providers/settings_provider.dart';
import 'package:intl/intl.dart';

class BudgetSetupScreen extends ConsumerStatefulWidget {
  final Map<ExpenseCategory, double>? initialBudgets;
  
  const BudgetSetupScreen({super.key, this.initialBudgets});

  @override
  ConsumerState<BudgetSetupScreen> createState() => _BudgetSetupScreenState();
}

class _BudgetSetupScreenState extends ConsumerState<BudgetSetupScreen> {
  final Map<ExpenseCategory, TextEditingController> _categoryControllers = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadExistingBudget();
    for (final category in ExpenseCategory.values) {
      _categoryControllers[category] = TextEditingController();
    }
  }

  void _loadExistingBudget() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialBudgets != null && widget.initialBudgets!.isNotEmpty) {
        for (final entry in widget.initialBudgets!.entries) {
          _categoryControllers[entry.key]?.text = entry.value.toStringAsFixed(2);
        }
      } else {
        final budgetAsync = ref.read(budgetProvider);
        final budget = budgetAsync.valueOrNull;
        if (budget != null) {
          for (final entry in budget.categoryBudgets.entries) {
            _categoryControllers[entry.key]?.text = entry.value.toStringAsFixed(2);
          }
        }
      }
    });
  }

  @override
  void dispose() {
    for (final controller in _categoryControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  double _calculateMonthlyBudget() {
    final profileAsync = ref.read(financialProfileProvider);
    final profile = profileAsync.valueOrNull;
    
    if (profile?.monthlyIncome == null || profile!.monthlyIncome! <= 0) {
      return 0.0;
    }
    
    final savingsPercentage = profile.savingsGoalPercentage ?? 20.0;
    final monthlyIncome = profile.monthlyIncome!;
    return monthlyIncome * (1 - savingsPercentage / 100);
  }

  Future<void> _saveBudget() async {
    final monthlyTotal = _calculateMonthlyBudget();
    
    if (monthlyTotal <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please set your monthly income and savings goal in Financial Profile first'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final categoryBudgets = <ExpenseCategory, double>{};
    for (final entry in _categoryControllers.entries) {
      final amount = double.tryParse(entry.value.text);
      if (amount != null && amount > 0) {
        categoryBudgets[entry.key] = amount;
      }
    }

    final budget = Budget(
      monthlyTotal: monthlyTotal,
      categoryBudgets: categoryBudgets,
    );

    await ref.read(budgetProvider.notifier).setBudget(budget);
    
    setState(() => _isLoading = false);
    
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Budget saved successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);
    final currency = settingsAsync.valueOrNull?.currency ?? Currency.USD;
    final profileAsync = ref.watch(financialProfileProvider);
    final profile = profileAsync.valueOrNull;
    final monthlyBudget = _calculateMonthlyBudget();
    final formatter = NumberFormat.currency(symbol: currency.name, decimalDigits: 2);

    return Scaffold(
      appBar: AppBar(
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          child: Text('Set Budget'),
        ),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _saveBudget,
              child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 140), // Increased bottom padding for nav
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Monthly Budget',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (monthlyBudget > 0) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Calculated Monthly Budget',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            formatter.format(monthlyBudget),
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (profile?.monthlyIncome != null && profile?.savingsGoalPercentage != null)
                      Text(
                        'Based on ${formatter.format(profile!.monthlyIncome!)} income with ${profile.savingsGoalPercentage!.toStringAsFixed(0)}% savings goal',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.error.withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Please set your monthly income and savings goal in Financial Profile first',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 32),
            Text(
              'Category Budgets (Optional)',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Set individual budgets for each category. Leave empty to use only the total budget.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (monthlyBudget > 0) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Total available: ${formatter.format(monthlyBudget)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            ...ExpenseCategory.values.map((category) {
              final categoryInfo = CategoryInfo.getInfo(category);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextField(
                  controller: _categoryControllers[category],
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: categoryInfo.name,
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(categoryInfo.emoji, style: const TextStyle(fontSize: 20)),
                    ),
                    prefixText: '${currency.name} ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              );
            }),
            if (monthlyBudget > 0) ...[
              const SizedBox(height: 16),
              Builder(
                builder: (context) {
                  final totalCategoryBudgets = _categoryControllers.values
                      .fold<double>(0.0, (sum, controller) {
                    final amount = double.tryParse(controller.text);
                    return sum + (amount ?? 0.0);
                  });
                  final remaining = monthlyBudget - totalCategoryBudgets;
                  final isOverBudget = totalCategoryBudgets > monthlyBudget;
                  
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isOverBudget
                          ? Theme.of(context).colorScheme.errorContainer.withOpacity(0.3)
                          : Theme.of(context).colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isOverBudget
                            ? Theme.of(context).colorScheme.error.withOpacity(0.3)
                            : Theme.of(context).colorScheme.outline.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Category Budgets Total',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            Flexible(
                              child: Text(
                                formatter.format(totalCategoryBudgets),
                                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isOverBudget
                                      ? Theme.of(context).colorScheme.error
                                      : null,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              isOverBudget ? 'Over budget by' : 'Remaining',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            Flexible(
                              child: Text(
                                formatter.format(remaining.abs()),
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isOverBudget
                                      ? Theme.of(context).colorScheme.error
                                      : Theme.of(context).colorScheme.primary,
                                ),
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
