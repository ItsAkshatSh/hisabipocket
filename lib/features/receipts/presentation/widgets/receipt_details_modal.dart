import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisabi/features/receipts/providers/receipt_provider.dart';
import 'package:hisabi/features/receipts/presentation/widgets/receipt_split_modal.dart';
import 'package:hisabi/core/models/receipt_model.dart';
import 'package:hisabi/core/models/category_model.dart';
import 'package:hisabi/features/settings/providers/settings_provider.dart';
import 'package:hisabi/features/receipts/providers/receipts_store.dart';
import 'package:intl/intl.dart';

class ReceiptDetailsModal extends ConsumerWidget {
  final String receiptId;
  const ReceiptDetailsModal({super.key, required this.receiptId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receiptAsync = ref.watch(receiptDetailsProvider(receiptId));
    final settingsAsync = ref.watch(settingsProvider);
    final userCurrency = settingsAsync.valueOrNull?.currency;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, controller) => receiptAsync.when(
        data: (receipt) {
          // Use the user's current currency setting for display consistency.
          final currencyCode = (userCurrency ?? receipt.currency).name;
          final currencyFormatter = NumberFormat.currency(
            symbol: currencyCode,
            decimalDigits: 2,
          );
          final category = receipt.primaryCategory ?? receipt.calculatedPrimaryCategory;
          final categoryInfo = category != null 
              ? CategoryInfo.getInfo(category) 
              : CategoryInfo.getInfo(ExpenseCategory.other);
          final cs = Theme.of(context).colorScheme;
          final categoryAccent = category != null
              ? CategoryInfo.themedColor(context, category)
              : cs.outlineVariant;

          return Column(
            children: [
              // Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            receipt.name,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (receipt.isSplit)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: cs.secondary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: cs.secondary.withOpacity(0.25)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.call_split, size: 14, color: cs.secondary),
                                SizedBox(width: 6),
                                Text(
                                  'SPLIT',
                                  style: TextStyle(
                                    color: cs.secondary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        IconButton(
                          tooltip: 'Remove expense',
                          icon: const Icon(Icons.delete_outline_rounded),
                          color: cs.error,
                          onPressed: () async {
                            final deletedReceipt = receipt;
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (dialogContext) {
                                final csDialog = Theme.of(dialogContext).colorScheme;
                                final title = deletedReceipt.isSplit
                                    ? 'Remove split expense?'
                                    : 'Remove expense?';
                                final description = deletedReceipt.isSplit
                                    ? 'This will permanently delete "${deletedReceipt.name}" and all its splits.'
                                    : 'This will permanently delete "${deletedReceipt.name}".';
                                return AlertDialog(
                                  title: Text(title),
                                  content: Text(description,
                                      style: TextStyle(
                                        color: csDialog.onSurfaceVariant,
                                      )),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(dialogContext).pop(false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.of(dialogContext).pop(true),
                                      child: Text(
                                        'Remove',
                                        style: TextStyle(color: csDialog.error),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            );

                            if (confirmed != true) return;

                            await ref.read(receiptsStoreProvider.notifier).delete(receipt.id);
                            if (!context.mounted) return;

                            // Show undo snackbar before closing the sheet.
                            final messenger = ScaffoldMessenger.of(context);
                            messenger
                              ..hideCurrentSnackBar()
                              ..showSnackBar(
                                SnackBar(
                                  behavior: SnackBarBehavior.floating,
                                  margin: const EdgeInsets.all(16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  content: const Text(
                                    'Expense removed',
                                    style: TextStyle(fontWeight: FontWeight.w700),
                                  ),
                                  action: SnackBarAction(
                                    label: 'Undo',
                                    textColor: cs.error,
                                    onPressed: () async {
                                      await ref
                                          .read(receiptsStoreProvider.notifier)
                                          .add(deletedReceipt);
                                    },
                                  ),
                                ),
                              );

                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildInfoChip(
                            context, 
                            categoryInfo.icon, 
                            categoryInfo.name, 
                            backgroundColor: categoryAccent.withOpacity(0.16),
                            labelColor: cs.onSurfaceVariant,
                          ),
                          const SizedBox(width: 12),
                          _buildInfoChip(context, Icons.store_outlined, receipt.store),
                          const SizedBox(width: 12),
                          _buildInfoChip(context, Icons.calendar_today_outlined, DateFormat('MMM d, yyyy').format(receipt.date)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Content
              Expanded(
                child: ListView.builder(
                  controller: controller,
                  itemCount: receipt.items.length + (receipt.isSplit ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (receipt.isSplit && index == receipt.items.length) {
                      return _buildSplitsSection(context, receipt, currencyCode);
                    }
                    final item = receipt.items[index];
                    final itemCategoryInfo = item.category != null ? CategoryInfo.getInfo(item.category!) : null;
                    final itemAccent = item.category != null
                        ? CategoryInfo.themedColor(context, item.category!)
                        : null;
                    
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${item.quantity.toInt()} x ${currencyFormatter.format(item.price)}',
                          ),
                          if (itemCategoryInfo != null)
                            Text(
                              itemCategoryInfo.name,
                              style: TextStyle(
                                color: itemAccent ?? itemCategoryInfo.color,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                      trailing: Text(
                        currencyFormatter.format(item.total),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    );
                  },
                ),
              ),
              // Footer with Total and Actions
              Container(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + MediaQuery.of(context).viewPadding.bottom + 120),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      offset: const Offset(0, -4),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Amount',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          currencyFormatter.format(receipt.total),
                          style: TextStyle(
                            fontWeight: FontWeight.w900, 
                            fontSize: 22,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          useSafeArea: true,
                          builder: (context) => ReceiptSplitModal(receiptId: receipt.id),
                        );
                      },
                      icon: const Icon(Icons.call_split),
                      label: Text(receipt.isSplit ? 'Edit Split' : 'Split Receipt'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 56),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildInfoChip(
    BuildContext context,
    IconData? icon,
    String label, {
    Color? backgroundColor,
    Color? labelColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor ?? Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null)
            Icon(icon, size: 16, color: labelColor ?? Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: labelColor ?? Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSplitsSection(BuildContext context, ReceiptModel receipt, String currencyCode) {
    final currencyFormatter = NumberFormat.currency(
      symbol: currencyCode,
      decimalDigits: 2,
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const SizedBox(height: 16),
          Text(
            'SPLITS',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          ...receipt.splits.map((split) {
            final splitCategoryInfo = split.category != null 
                ? CategoryInfo.getInfo(split.category!) 
                : null;
            final splitAccent = split.category != null
                ? CategoryInfo.themedColor(context, split.category!)
                : null;
            
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(split.label, style: const TextStyle(fontWeight: FontWeight.w600)),
                      if (splitCategoryInfo != null)
                        Text(
                          splitCategoryInfo.name,
                          style: TextStyle(
                            fontSize: 12,
                            color: splitAccent ?? splitCategoryInfo.color,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                    ],
                  ),
                  Text(
                    currencyFormatter.format(split.amount),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
