import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisabi/features/receipts/providers/receipt_provider.dart';

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
              child: Text(receipt.name, style: Theme.of(context).textTheme.headlineSmall),
            ),
            // Content
            Expanded(
              child: ListView.builder(
                controller: controller,
                itemCount: receipt.items.length,
                itemBuilder: (context, index) {
                  final item = receipt.items[index];
                  return ListTile(
                    title: Text(item.name),
                    subtitle: Text('${item.quantity} x ${item.price}'),
                    trailing: Text(item.total.toStringAsFixed(2)),
                  );
                },
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
