import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisabi/core/models/receipt_model.dart';
import 'package:hisabi/core/storage/storage_service.dart';
import 'package:hisabi/features/auth/providers/auth_provider.dart';

final receiptsStoreProvider =
    StateNotifierProvider.autoDispose<ReceiptsStore, AsyncValue<List<ReceiptModel>>>(
  (ref) {
    final authState = ref.watch(authProvider);
    final store = ReceiptsStore();
    
    if (authState.status == AuthStatus.authenticated && authState.user != null) {
      store.loadReceipts();
    }
    
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (previous?.user?.email != next.user?.email) {
        store.loadReceipts();
      }
    });
    
    return store;
  },
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








