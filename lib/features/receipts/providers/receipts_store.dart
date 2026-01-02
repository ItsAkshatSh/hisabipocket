import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisabi/core/models/receipt_model.dart';
import 'package:hisabi/core/storage/storage_service.dart';

/// Persistent store of receipts with local storage.
final receiptsStoreProvider =
    StateNotifierProvider<ReceiptsStore, AsyncValue<List<ReceiptModel>>>(
  (ref) => ReceiptsStore()..loadReceipts(),
);

class ReceiptsStore extends StateNotifier<AsyncValue<List<ReceiptModel>>> {
  ReceiptsStore() : super(const AsyncValue.loading());

  Future<void> loadReceipts() async {
    state = const AsyncValue.loading();
    try {
      final receipts = await StorageService.loadReceipts();
      state = AsyncValue.data(receipts);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> add(ReceiptModel receipt) async {
    // Generate a unique ID if not provided
    final receiptWithId = receipt.id.isEmpty
        ? ReceiptModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            name: receipt.name,
            date: receipt.date,
            store: receipt.store,
            items: receipt.items,
            total: receipt.total,
          )
        : receipt;

    // Persist to storage first
    try {
      await StorageService.addReceipt(receiptWithId);
      
      // After successful save, update local state
      final currentReceipts = state.valueOrNull ?? [];
      state = AsyncValue.data([...currentReceipts, receiptWithId]);
    } catch (e) {
      print('Error adding receipt to storage: $e');
      // If persistence fails, reload from storage to sync
      await loadReceipts();
      rethrow;
    }
  }

  Future<void> delete(String receiptId) async {
    final currentReceipts = state.valueOrNull ?? [];
    state = AsyncValue.data(
      currentReceipts.where((r) => r.id != receiptId).toList(),
    );

    try {
      await StorageService.deleteReceipt(receiptId);
    } catch (e) {
      await loadReceipts();
      rethrow;
    }
  }

  Future<void> refresh() async {
    await loadReceipts();
  }
}








