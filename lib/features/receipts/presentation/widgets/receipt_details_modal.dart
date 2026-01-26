import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisabi/features/receipts/providers/receipt_provider.dart';
import 'package:hisabi/features/receipts/presentation/widgets/receipt_split_modal.dart';

class ReceiptDetailsModal extends ConsumerWidget {
  final String receiptId;
  const ReceiptDetailsModal({super.key, required this.receiptId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receiptAsync = ref.watch(receiptDetailsProvider(receiptId));

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (_, controller) => receiptAsync.when(
        data: (receipt) => Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      receipt.name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  if (receipt.isSplit)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.call_split, size: 16, color: Colors.blue),
                          const SizedBox(width: 4),
                          Text(
                            'Split',
                            style: TextStyle(
                              color: Colors.blue,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: ListView.builder(
                controller: controller,
                itemCount: receipt.items.length + (receipt.isSplit ? 1 : 0),
                itemBuilder: (context, index) {
                  if (receipt.isSplit && index == receipt.items.length) {
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(),
                          const SizedBox(height: 8),
                          Text(
                            'Splits',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...receipt.splits.map((split) => ListTile(
                            title: Text(split.label),
                            subtitle: split.category != null
                                ? Text(split.category!.name)
                                : null,
                            trailing: Text(split.amount.toStringAsFixed(2)),
                            dense: true,
                          )),
                        ],
                      ),
                    );
                  }
                  final item = receipt.items[index];
                  return ListTile(
                    title: Text(item.name),
                    subtitle: Text('${item.quantity} x ${item.price}'),
                    trailing: Text(item.total.toStringAsFixed(2)),
                  );
                },
              ),
            ),
            // Actions
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
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
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
