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
  
  // Cache to avoid redundant loads
  List<ReceiptModel>? _cachedReceipts;
  DateTime? _lastLoadTime;
  static const _cacheValidDuration = Duration(seconds: 5);

  Future<void> loadReceipts({bool forceRefresh = false}) async {
    // Use cache if available and not expired
    if (!forceRefresh && 
        _cachedReceipts != null && 
        _lastLoadTime != null &&
        DateTime.now().difference(_lastLoadTime!) < _cacheValidDuration) {
      state = AsyncValue.data(_cachedReceipts!);
      return;
    }

    state = const AsyncValue.loading();
    try {
      final receipts = await StorageService.loadReceipts();
      _cachedReceipts = receipts;
      _lastLoadTime = DateTime.now();
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

    // Optimistically update UI first
    final currentReceipts = state.valueOrNull ?? [];
    state = AsyncValue.data([...currentReceipts, receiptWithId]);
    _cachedReceipts = [...currentReceipts, receiptWithId];
    _lastLoadTime = DateTime.now();

    // Persist to storage in background
    try {
      await StorageService.addReceipt(receiptWithId);
    } catch (e) {
      print('Error adding receipt to storage: $e');
      // Revert on error
      state = AsyncValue.data(currentReceipts);
      _cachedReceipts = currentReceipts;
      await loadReceipts(forceRefresh: true);
      rethrow;
    }
  }

  Future<void> delete(String receiptId) async {
    final currentReceipts = state.valueOrNull ?? [];
    final updatedReceipts = currentReceipts.where((r) => r.id != receiptId).toList();
    
    // Optimistically update UI first
    state = AsyncValue.data(updatedReceipts);
    _cachedReceipts = updatedReceipts;
    _lastLoadTime = DateTime.now();

    // Persist to storage in background
    try {
      await StorageService.deleteReceipt(receiptId);
    } catch (e) {
      print('Error deleting receipt from storage: $e');
      // Revert on error
      state = AsyncValue.data(currentReceipts);
      _cachedReceipts = currentReceipts;
      await loadReceipts(forceRefresh: true);
      rethrow;
    }
  }

  Future<void> refresh() async {
    await loadReceipts();
  }
}








