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
      _labelControllers[newId] = TextEditingController(text: 'Split ${_splits.length + 1}');
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
      final amountText = _amountControllers[split.id]?.text.replaceAll(',', '') ?? '0';
      final amount = double.tryParse(amountText) ?? 0.0;
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
      currency: receipt.currency,
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

    return receiptAsync.when(
      data: (receipt) {
        final totalSplit = _splits.fold<double>(
          0.0,
          (sum, split) {
            final text = _amountControllers[split.id]?.text.replaceAll(',', '') ?? '0';
            return sum + (double.tryParse(text) ?? 0.0);
          },
        );
        final remaining = receipt.total - totalSplit;

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          appBar: AppBar(
            title: const Text('Split Receipt', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24)),
            centerTitle: false,
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              TextButton(
                onPressed: _saveSplits,
                child: Text('Save', style: TextStyle(
                  fontWeight: FontWeight.w900, 
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 16,
                )),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Column(
            children: [
              Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    _buildSummaryRow(context, 'Total', '${receipt.currency.name} ${receipt.total.toStringAsFixed(2)}', isBold: true, fontSize: 24),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Divider(height: 1),
                    ),
                    _buildSummaryRow(context, 'Split Total', '${receipt.currency.name} ${totalSplit.toStringAsFixed(2)}'),
                    const SizedBox(height: 12),
                    _buildSummaryRow(
                      context, 
                      'Remaining', 
                      '${receipt.currency.name} ${remaining.toStringAsFixed(2)}',
                      color: remaining < 0 ? Colors.red : remaining > 0 ? Colors.orange : Colors.green,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _splits.length,
                  itemBuilder: (context, index) {
                    final split = _splits[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _labelControllers[split.id],
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                  decoration: InputDecoration(
                                    labelText: 'Label',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    filled: true,
                                    fillColor: Theme.of(context).colorScheme.surface,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              IconButton.filledTonal(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                onPressed: () => _removeSplit(split.id),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: TextField(
                                  controller: _amountControllers[split.id],
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  onChanged: (_) => setState(() {}),
                                  decoration: InputDecoration(
                                    labelText: 'Amount',
                                    prefixText: '${receipt.currency.name} ',
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    filled: true,
                                    fillColor: Theme.of(context).colorScheme.surface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<ExpenseCategory?>(
                            value: _categorySelections[split.id],
                            decoration: InputDecoration(
                              labelText: 'Category',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              filled: true,
                              fillColor: Theme.of(context).colorScheme.surface,
                            ),
                            items: [
                              const DropdownMenuItem<ExpenseCategory?>(
                                value: null,
                                child: Text('Default Category'),
                              ),
                              ...ExpenseCategory.values.map((category) {
                                final info = CategoryInfo.getInfo(category);
                                return DropdownMenuItem<ExpenseCategory?>(
                                  value: category,
                                  child: Row(
                                    children: [
                                      Text(info.emoji),
                                      const SizedBox(width: 10),
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
                    );
                  },
                ),
              ),
              // Footer button
              Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + MediaQuery.of(context).viewPadding.bottom + 120), // Increased bottom padding to 120
                child: ElevatedButton.icon(
                  onPressed: _addSplit,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add Split Entry', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                    foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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

  Widget _buildSummaryRow(BuildContext context, String label, String value, {bool isBold = false, double fontSize = 16, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: isBold ? FontWeight.w900 : FontWeight.w800,
            fontSize: fontSize,
            color: color ?? Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
