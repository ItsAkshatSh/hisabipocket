import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisabi/features/receipts/providers/receipt_provider.dart';
import 'package:hisabi/features/receipts/presentation/widgets/receipt_split_modal.dart';
import 'package:hisabi/core/models/receipt_model.dart';
import 'package:hisabi/core/models/category_model.dart';
import 'package:intl/intl.dart';

class ReceiptDetailsModal extends ConsumerWidget {
  final String receiptId;
  const ReceiptDetailsModal({super.key, required this.receiptId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receiptAsync = ref.watch(receiptDetailsProvider(receiptId));

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, controller) => receiptAsync.when(
        data: (receipt) {
          // Get primary category from receipt using the same logic as the budget card
          final category = receipt.primaryCategory ?? receipt.calculatedPrimaryCategory;
          final categoryInfo = category != null 
              ? CategoryInfo.getInfo(category) 
              : CategoryInfo.getInfo(ExpenseCategory.other);

          return Column(
            children: [
              // Handle for DraggableScrollableSheet
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
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.blue.withOpacity(0.2)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.call_split, size: 14, color: Colors.blue),
                                const SizedBox(width: 6),
                                const Text(
                                  'SPLIT',
                                  style: TextStyle(
                                    color: Colors.blue,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ],
                            ),
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
                            null, 
                            categoryInfo.name, 
                            emoji: categoryInfo.emoji,
                            backgroundColor: categoryInfo.color.withOpacity(0.8), // High opacity colored chip
                            labelColor: Colors.white,
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
                      return _buildSplitsSection(context, receipt);
                    }
                    final item = receipt.items[index];
                    final itemCategoryInfo = item.category != null ? CategoryInfo.getInfo(item.category!) : null;
                    
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                      title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${item.quantity.toInt()} x ${receipt.currency.name} ${item.price.toStringAsFixed(2)}'),
                          if (itemCategoryInfo != null)
                            Text(
                              itemCategoryInfo.name,
                              style: TextStyle(
                                color: itemCategoryInfo.color,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                        ],
                      ),
                      trailing: Text(
                        '${receipt.currency.name} ${item.total.toStringAsFixed(2)}',
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
                          '${receipt.currency.name} ${receipt.total.toStringAsFixed(2)}',
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

  Widget _buildInfoChip(BuildContext context, IconData? icon, String label, {String? emoji, Color? backgroundColor, Color? labelColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8), // Slightly taller
      decoration: BoxDecoration(
        color: backgroundColor ?? Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.9), // Higher opacity
        borderRadius: BorderRadius.circular(12), // Rounder corners
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (emoji != null)
            Text(emoji, style: const TextStyle(fontSize: 16))
          else if (icon != null)
            Icon(icon, size: 16, color: labelColor ?? Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 13, // Slightly larger
              color: labelColor ?? Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSplitsSection(BuildContext context, ReceiptModel receipt) {
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
                            color: splitCategoryInfo.color,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                    ],
                  ),
                  Text(
                    '${receipt.currency.name} ${split.amount.toStringAsFixed(2)}',
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
