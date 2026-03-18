import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hisabi/core/services/quick_start_service.dart';
import 'package:hisabi/features/budgets/providers/budget_provider.dart';
import 'package:hisabi/features/financial_profile/providers/financial_profile_provider.dart';
import 'package:hisabi/features/settings/providers/settings_provider.dart';
import 'package:intl/intl.dart';

enum BudgetSetupStyle { simple, categoryBased }

class QuickStartSheet extends ConsumerStatefulWidget {
  const QuickStartSheet({super.key});

  @override
  ConsumerState<QuickStartSheet> createState() => _QuickStartSheetState();
}

class _QuickStartSheetState extends ConsumerState<QuickStartSheet> {
  int _step = 0;
  Currency? _currency;
  final TextEditingController _incomeController = TextEditingController();
  double _savingsGoal = 20;
  BudgetSetupStyle _budgetStyle = BudgetSetupStyle.simple;

  @override
  void dispose() {
    _incomeController.dispose();
    super.dispose();
  }

  double? get _incomeValue {
    final text = _incomeController.text.replaceAll(',', '').trim();
    if (text.isEmpty) return null;
    return double.tryParse(text);
  }

  bool get _canContinue {
    switch (_step) {
      case 0:
        return _currency != null;
      case 1:
        return (_incomeValue ?? 0) > 0;
      default:
        return true;
    }
  }

  Future<void> _finish() async {
    final selectedCurrency = _currency;
    final income = _incomeValue;

    if (selectedCurrency != null) {
      await ref.read(settingsProvider.notifier).setCurrency(selectedCurrency);
    }

    if (income != null && income > 0) {
      await ref.read(financialProfileProvider.notifier).setMonthlyIncome(income);
      await ref
          .read(financialProfileProvider.notifier)
          .setSavingsGoal(_savingsGoal);

      final spendable = income * (1 - (_savingsGoal / 100));
      await ref.read(budgetProvider.notifier).updateMonthlyTotal(spendable);
    }

    await QuickStartService.setCompletedQuickStart();
    if (!mounted) return;

    Navigator.of(context).pop();

    if (_budgetStyle == BudgetSetupStyle.categoryBased) {
      context.go('/budget-setup');
    }
  }

  Future<void> _skip() async {
    await QuickStartService.setCompletedQuickStart();
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final settings = ref.watch(settingsProvider).valueOrNull;
    _currency ??= settings?.currency;

    final steps = <Widget>[
      _CurrencyStep(
        currency: _currency,
        onChanged: (c) => setState(() => _currency = c),
      ),
      _IncomeStep(
        currency: _currency ?? Currency.USD,
        controller: _incomeController,
        onChanged: (_) => setState(() {}),
      ),
      _SavingsStep(
        savingsGoal: _savingsGoal,
        onChanged: (v) => setState(() => _savingsGoal = v),
      ),
      _BudgetStyleStep(
        style: _budgetStyle,
        onChanged: (v) => setState(() => _budgetStyle = v),
      ),
      _ReviewStep(
        currency: _currency ?? Currency.USD,
        income: _incomeValue,
        savingsGoal: _savingsGoal,
        style: _budgetStyle,
      ),
    ];

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  'Quick Start',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: _skip,
                  child: const Text('Finish later'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: (_step + 1) / steps.length,
              backgroundColor: colorScheme.surfaceContainerHighest,
            ),
            const SizedBox(height: 14),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: KeyedSubtree(
                key: ValueKey(_step),
                child: steps[_step],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                if (_step > 0)
                  OutlinedButton(
                    onPressed: () => setState(() => _step -= 1),
                    child: const Text('Back'),
                  )
                else
                  const SizedBox.shrink(),
                const Spacer(),
                if (_step < steps.length - 1)
                  FilledButton(
                    onPressed: _canContinue ? () => setState(() => _step += 1) : null,
                    child: const Text('Continue'),
                  )
                else
                  FilledButton(
                    onPressed: _finish,
                    child: Text(
                      _budgetStyle == BudgetSetupStyle.categoryBased
                          ? 'Finish & Customize'
                          : 'Finish',
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

class _CurrencyStep extends StatelessWidget {
  final Currency? currency;
  final ValueChanged<Currency> onChanged;

  const _CurrencyStep({required this.currency, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Pick your currency',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'This helps us format totals and budgets correctly.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        DropdownMenu<Currency>(
          expandedInsets: EdgeInsets.zero,
          initialSelection: currency,
          label: const Text('Currency'),
          dropdownMenuEntries: Currency.values
              .map((c) => DropdownMenuEntry(value: c, label: c.name))
              .toList(),
          onSelected: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ],
    );
  }
}

class _IncomeStep extends StatelessWidget {
  final Currency currency;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _IncomeStep({
    required this.currency,
    required this.controller,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Monthly income',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'A rough number is fine — you can edit this later.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          decoration: InputDecoration(
            labelText: 'Income',
            prefixText: '${currency.name} ',
            border: const OutlineInputBorder(),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _SavingsStep extends StatelessWidget {
  final double savingsGoal;
  final ValueChanged<double> onChanged;

  const _SavingsStep({required this.savingsGoal, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pct = savingsGoal.round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Savings goal',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'We’ll compute a spending limit from this.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainerLow,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$pct%',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Slider(
                  value: savingsGoal,
                  min: 0,
                  max: 40,
                  divisions: 40,
                  label: '$pct%',
                  onChanged: onChanged,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BudgetStyleStep extends StatelessWidget {
  final BudgetSetupStyle style;
  final ValueChanged<BudgetSetupStyle> onChanged;

  const _BudgetStyleStep({required this.style, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Budget style',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'Choose simple now. You can always switch later.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        SegmentedButton<BudgetSetupStyle>(
          segments: const [
            ButtonSegment(
              value: BudgetSetupStyle.simple,
              label: Text('Simple'),
              icon: Icon(Icons.auto_graph_rounded),
            ),
            ButtonSegment(
              value: BudgetSetupStyle.categoryBased,
              label: Text('Categories'),
              icon: Icon(Icons.category_rounded),
            ),
          ],
          selected: {style},
          onSelectionChanged: (s) => onChanged(s.first),
        ),
      ],
    );
  }
}

class _ReviewStep extends StatelessWidget {
  final Currency currency;
  final double? income;
  final double savingsGoal;
  final BudgetSetupStyle style;

  const _ReviewStep({
    required this.currency,
    required this.income,
    required this.savingsGoal,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatter = NumberFormat.currency(symbol: currency.name, decimalDigits: 2);
    final incomeValue = income ?? 0;
    final spendable = incomeValue * (1 - (savingsGoal / 100));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Review',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        Card(
          elevation: 0,
          color: theme.colorScheme.surfaceContainerLow,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _row(theme, 'Currency', currency.name),
                const SizedBox(height: 8),
                _row(theme, 'Income',
                    incomeValue > 0 ? formatter.format(incomeValue) : '—'),
                const SizedBox(height: 8),
                _row(theme, 'Savings goal', '${savingsGoal.round()}%'),
                const SizedBox(height: 8),
                _row(theme, 'Monthly limit',
                    incomeValue > 0 ? formatter.format(spendable) : '—'),
                const SizedBox(height: 8),
                _row(
                  theme,
                  'Style',
                  style == BudgetSetupStyle.simple ? 'Simple' : 'Category-based',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _row(ThemeData theme, String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
      ],
    );
  }
}

