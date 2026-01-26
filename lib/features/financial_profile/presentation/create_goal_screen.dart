import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisabi/core/widgets/widget_summary.dart';
import 'package:hisabi/features/financial_profile/providers/goals_provider.dart';
import 'package:hisabi/features/settings/providers/settings_provider.dart';
import 'package:intl/intl.dart';

class CreateGoalScreen extends ConsumerStatefulWidget {
  final SavingsGoal? existingGoal;
  const CreateGoalScreen({super.key, this.existingGoal});

  @override
  ConsumerState<CreateGoalScreen> createState() => _CreateGoalScreenState();
}

class _CreateGoalScreenState extends ConsumerState<CreateGoalScreen> {
  final _titleController = TextEditingController();
  final _targetAmountController = TextEditingController();
  final _currentAmountController = TextEditingController();
  DateTime? _targetDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingGoal != null) {
      _titleController.text = widget.existingGoal!.title;
      _targetAmountController.text = widget.existingGoal!.targetAmount.toStringAsFixed(2);
      _currentAmountController.text = widget.existingGoal!.currentAmount.toStringAsFixed(2);
      _targetDate = widget.existingGoal!.targetDate;
    } else {
      _targetDate = DateTime.now().add(const Duration(days: 30));
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _targetAmountController.dispose();
    _currentAmountController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (date != null) {
      setState(() => _targetDate = date);
    }
  }

  Future<void> _saveGoal() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a goal title')),
      );
      return;
    }

    final targetAmount = double.tryParse(_targetAmountController.text);
    if (targetAmount == null || targetAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid target amount')),
      );
      return;
    }

    final currentAmount = double.tryParse(_currentAmountController.text) ?? 0.0;
    if (currentAmount < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Current amount cannot be negative')),
      );
      return;
    }

    if (_targetDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a target date')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final goal = SavingsGoal(
      title: _titleController.text,
      targetAmount: targetAmount,
      currentAmount: currentAmount,
      targetDate: _targetDate!,
    );

    if (widget.existingGoal != null) {
      await ref.read(savingsGoalsProvider.notifier).updateGoal(goal);
    } else {
      await ref.read(savingsGoalsProvider.notifier).addGoal(goal);
    }

    setState(() => _isLoading = false);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.existingGoal != null ? 'Goal updated' : 'Goal created')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);
    final currency = settingsAsync.valueOrNull?.currency ?? Currency.USD;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingGoal != null ? 'Edit Goal' : 'Create Goal'),
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
              onPressed: _saveGoal,
              child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Goal Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _targetAmountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Target Amount',
                prefixText: '${currency.name} ',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _currentAmountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Current Amount',
                prefixText: '${currency.name} ',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _selectDate,
              icon: const Icon(Icons.calendar_today),
              label: Text(
                _targetDate == null
                    ? 'Select Target Date'
                    : DateFormat.yMMMd().format(_targetDate!),
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

