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
      if (previous?.user?.email != next.user?.email && next.status == AuthStatus.authenticated) {
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
  static const _cacheValidDuration = Duration(minutes: 1);

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
    final receiptWithId = (receipt.id.isEmpty || receipt.id == '0')
        ? ReceiptModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            name: receipt.name,
            date: receipt.date,
            store: receipt.store,
            items: receipt.items,
            total: receipt.total,
            primaryCategory: receipt.primaryCategory,
          )
        : receipt;

    // Optimistically update UI first
    final currentReceipts = state.valueOrNull ?? [];
    final updatedReceipts = [...currentReceipts, receiptWithId];
    state = AsyncValue.data(updatedReceipts);
    _cachedReceipts = updatedReceipts;
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

  /// Update an existing receipt; persists full list after modification.
  Future<void> update(ReceiptModel updated) async {
    final currentReceipts = state.valueOrNull ?? [];
    final index = currentReceipts.indexWhere((r) => r.id == updated.id);
    if (index == -1) return;

    final updatedReceipts = List<ReceiptModel>.from(currentReceipts);
    updatedReceipts[index] = updated;

    state = AsyncValue.data(updatedReceipts);
    _cachedReceipts = updatedReceipts;
    _lastLoadTime = DateTime.now();

    try {
      // Persist the entire list since storage only supports saveAll semantics
      await StorageService.saveReceipts(updatedReceipts);
    } catch (e) {
      print('Error updating receipt in storage: $e');
      // revert on error
      state = AsyncValue.data(currentReceipts);
      _cachedReceipts = currentReceipts;
      await loadReceipts(forceRefresh: true);
      rethrow;
    }
  }

  Future<void> refresh() async {
    await loadReceipts(forceRefresh: true);
  }
}
