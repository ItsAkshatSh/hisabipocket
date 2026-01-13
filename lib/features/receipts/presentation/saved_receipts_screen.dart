import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hisabi/core/utils/theme_extensions.dart';
import 'package:hisabi/features/receipts/providers/receipts_store.dart';
import 'package:hisabi/features/receipts/presentation/widgets/receipt_details_modal.dart';

class SavedReceiptsScreen extends ConsumerWidget {
  const SavedReceiptsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receiptsAsync = ref.watch(receiptsStoreProvider);
    final formatter = NumberFormat.currency(symbol: 'USD', decimalDigits: 2);

    return Scaffold(
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          slivers: [
            const SliverAppBar.large(
              title: Text('Saved Receipts'),
              centerTitle: false,
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16.0),
              sliver: receiptsAsync.when(
                data: (receipts) => receipts.isEmpty
                    ? const SliverFillRemaining(child: _EmptyState())
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final r = receipts[receipts.length - 1 - index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Card(
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  leading: CircleAvatar(
                                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                                    child: Icon(Icons.shopping_bag, color: Theme.of(context).colorScheme.primary),
                                  ),
                                  title: Text(r.store, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text(DateFormat.yMMMd().format(r.date)),
                                  trailing: Text(
                                    formatter.format(r.total),
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                  onTap: () => showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    builder: (_) => ReceiptDetailsModal(receiptId: r.id),
                                  ),
                                ),
                              ).animate().fadeIn(delay: Duration(milliseconds: 50 * index)).slideX(),
                            );
                          },
                          childCount: receipts.length,
                        ),
                      ),
                loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
                error: (error, stack) => SliverFillRemaining(child: Center(child: Text('Error loading receipts'))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 80, color: Theme.of(context).colorScheme.outlineVariant),
          const SizedBox(height: 24),
          Text(
            'No receipts saved yet',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Start tracking your expenses by adding your first receipt',
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ).animate().fadeIn(),
    );
  }
}
