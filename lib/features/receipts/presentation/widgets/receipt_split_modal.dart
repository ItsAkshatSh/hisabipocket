import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisabi/core/models/category_model.dart';
import 'package:hisabi/core/models/receipt_model.dart';
import 'package:hisabi/features/receipts/models/receipt_split_model.dart';
import 'package:hisabi/features/receipts/providers/receipt_provider.dart';
import 'package:hisabi/features/settings/providers/settings_provider.dart';
import 'package:intl/intl.dart';

class ReceiptSplitModal extends ConsumerStatefulWidget {
  final String receiptId;
  const ReceiptSplitModal({super.key, required this.receiptId});

  @override
  ConsumerState<ReceiptSplitModal> createState() => _ReceiptSplitModalState();
}

class _ReceiptSplitModalState extends ConsumerState<ReceiptSplitModal> {
  final List<ReceiptSplit> _splits = [];
  final Map<String, TextEditingController> _amountControllers = {};
  final Map<String, TextEditingController> _labelControllers = {};
  final Map<String, ExpenseCategory?> _categorySelections = {};

  @override
  void initState() {
    super.initState();
    _loadExistingSplits();
  }

  void _loadExistingSplits() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final receiptAsync = ref.read(receiptDetailsProvider(widget.receiptId));
      final receipt = receiptAsync.valueOrNull;
      if (receipt != null && receipt.splits.isNotEmpty) {
        setState(() {
          _splits.addAll(receipt.splits);
          for (final split in receipt.splits) {
            _amountControllers[split.id] = TextEditingController(text: split.amount.toStringAsFixed(2));
            _labelControllers[split.id] = TextEditingController(text: split.label);
            _categorySelections[split.id] = split.category;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    for (final controller in _amountControllers.values) {
      controller.dispose();
    }
    for (final controller in _labelControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addSplit() {
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    setState(() {
      _splits.add(ReceiptSplit(
        id: newId,
        label: 'Split ${_splits.length + 1}',
        amount: 0.0,
      ));
      _amountControllers[newId] = TextEditingController();
      _labelControllers[newId] = TextEditingController(text: 'Split ${_splits.length}');
      _categorySelections[newId] = null;
    });
  }

  void _removeSplit(String id) {
    setState(() {
      _splits.removeWhere((s) => s.id == id);
      _amountControllers[id]?.dispose();
      _labelControllers[id]?.dispose();
      _amountControllers.remove(id);
      _labelControllers.remove(id);
      _categorySelections.remove(id);
    });
  }

  Future<void> _saveSplits() async {
    final receiptAsync = ref.read(receiptDetailsProvider(widget.receiptId));
    final receipt = receiptAsync.valueOrNull;
    if (receipt == null) return;

    final updatedSplits = <ReceiptSplit>[];
    for (final split in _splits) {
      final amount = double.tryParse(_amountControllers[split.id]?.text ?? '0') ?? 0.0;
      final label = _labelControllers[split.id]?.text ?? split.label;
      if (amount > 0 && label.isNotEmpty) {
        updatedSplits.add(ReceiptSplit(
          id: split.id,
          label: label,
          amount: amount,
          category: _categorySelections[split.id],
        ));
      }
    }

    final updatedReceipt = ReceiptModel(
      id: receipt.id,
      name: receipt.name,
      date: receipt.date,
      store: receipt.store,
      items: receipt.items,
      total: receipt.total,
      primaryCategory: receipt.primaryCategory,
      splits: updatedSplits,
    );

    await ref.read(receiptProvider.notifier).updateReceipt(updatedReceipt);
    
    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Receipt split saved')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final receiptAsync = ref.watch(receiptDetailsProvider(widget.receiptId));
    final settingsAsync = ref.watch(settingsProvider);
    final currency = settingsAsync.valueOrNull?.currency ?? Currency.USD;
    final formatter = NumberFormat.currency(symbol: currency.name, decimalDigits: 2);

    return receiptAsync.when(
      data: (receipt) {
        final totalSplit = _splits.fold<double>(
          0.0,
          (sum, split) => sum + (double.tryParse(_amountControllers[split.id]?.text ?? '0') ?? 0.0),
        );
        final remaining = receipt.total - totalSplit;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Split Receipt'),
            actions: [
              TextButton(
                onPressed: _saveSplits,
                child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          body: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          formatter.format(receipt.total),
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Split Total',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          formatter.format(totalSplit),
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Remaining',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        Text(
                          formatter.format(remaining),
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: remaining < 0 ? Colors.red : remaining > 0 ? Colors.orange : Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _splits.length,
                  itemBuilder: (context, index) {
                    final split = _splits[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _labelControllers[split.id],
                                    decoration: const InputDecoration(
                                      labelText: 'Label',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline),
                                  onPressed: () => _removeSplit(split.id),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _amountControllers[split.id],
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: 'Amount',
                                prefixText: '${currency.name} ',
                                border: const OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<ExpenseCategory?>(
                              value: _categorySelections[split.id],
                              decoration: const InputDecoration(
                                labelText: 'Category (Optional)',
                                border: OutlineInputBorder(),
                              ),
                              items: [
                                const DropdownMenuItem<ExpenseCategory?>(
                                  value: null,
                                  child: Text('None'),
                                ),
                                ...ExpenseCategory.values.map((category) {
                                  final info = CategoryInfo.getInfo(category);
                                  return DropdownMenuItem<ExpenseCategory?>(
                                    value: category,
                                    child: Row(
                                      children: [
                                        Text(info.emoji),
                                        const SizedBox(width: 8),
                                        Text(info.name),
                                      ],
                                    ),
                                  );
                                }),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _categorySelections[split.id] = value;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: _addSplit,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Split'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('Error: $err'))),
    );
  }
}

