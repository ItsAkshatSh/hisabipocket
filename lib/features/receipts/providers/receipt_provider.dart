import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisabi/core/api/api_client.dart';
import 'package:hisabi/core/models/receipt_model.dart';
import 'package:hisabi/features/auth/providers/auth_provider.dart';
import 'package:hisabi/core/widgets/widget_summary.dart';
import 'package:hisabi/features/receipts/providers/receipts_store.dart';

final receiptDetailsProvider = FutureProvider.autoDispose.family<ReceiptModel, String>((ref, receiptId) async {
  // In a real app: 
  // final data = await client.get('/api/receipts/$receiptId');
  // return ReceiptModel.fromDetailJson(data);

  // Mocked response
  await Future.delayed(const Duration(milliseconds: 400));
  return ReceiptModel(
    id: receiptId,
    name: 'Mocked Receipt',
    date: DateTime.now(),
    store: 'Mocked Store',
    total: 123.45,
    items: [
      ReceiptItem(name: 'Item 1', quantity: 2, price: 10.0, total: 20.0),
      ReceiptItem(name: 'Item 2', quantity: 1, price: 103.45, total: 103.45),
    ]
  );
});

class ReceiptEntryState {
  final ReceiptModel? analyzedReceipt;
  final bool isAnalyzing;
  final String? analysisError;

  ReceiptEntryState({this.analyzedReceipt, this.isAnalyzing = false, this.analysisError});
  
  ReceiptEntryState copyWith({
    ReceiptModel? analyzedReceipt,
    bool? isAnalyzing,
    String? analysisError,
  }) => ReceiptEntryState(
    analyzedReceipt: analyzedReceipt ?? this.analyzedReceipt,
    isAnalyzing: isAnalyzing ?? this.isAnalyzing,
    analysisError: analysisError,
  );
}

final receiptEntryProvider =
    StateNotifierProvider<ReceiptEntryNotifier, ReceiptEntryState>((ref) {
  return ReceiptEntryNotifier(ref.watch(apiClientProvider), ref);
});

class ReceiptEntryNotifier extends StateNotifier<ReceiptEntryState> {
  final ApiClient _apiClient;
  final Ref _ref;

  ReceiptEntryNotifier(this._apiClient, this._ref) : super(ReceiptEntryState());

  // --- Core Logic ---

  Future<void> analyzeImage(File imageFile) async {
    state = state.copyWith(isAnalyzing: true, analysisError: null);
    
    // Simulate API call for AI extraction
    await Future.delayed(const Duration(seconds: 2));
    
    try {
      // For MVP, simulate a successful result with item data
      // In a real app, this would use _apiClient.uploadMultipart to /api/upload
      
      final items = [
        ReceiptItem(name: 'Milk', quantity: 1.0, price: 5.50, total: 5.50),
        ReceiptItem(name: 'Bread', quantity: 2.0, price: 3.00, total: 6.00),
        ReceiptItem(name: 'Apples (1kg)', quantity: 1.0, price: 12.00, total: 12.00),
      ];
      final total = items.fold(0.0, (sum, item) => sum + item.total);
      
      final resultReceipt = ReceiptModel(
        id: '', // ID assigned on save
        name: 'Scanned Receipt',
        date: DateTime.now(),
        store: 'Scanned Receipt',
        items: items,
        total: total,
      );
      
      state = state.copyWith(analyzedReceipt: resultReceipt, isAnalyzing: false);
      
    } catch (e) {
      state = state.copyWith(isAnalyzing: false, analysisError: 'AI Analysis failed. Try manual entry.');
    }
  }

  void setManualReceipt(ReceiptModel receipt) {
    state = state.copyWith(analyzedReceipt: receipt);
  }

  Future<bool> saveReceipt(String name, ReceiptModel receipt) async {
    // Always add to the in-memory store so dashboard & saved receipts refresh immediately.
    _ref.read(receiptsStoreProvider.notifier).add(receipt);

    // Try to sync to backend, but don't block local UX on network errors.
    try {
      await _apiClient.post('/api/save_receipt', {
        'name': name,
        'data': {
          'date': receipt.date.toIso8601String(),
          'store': receipt.store,
          'total': receipt.total,
          'items': receipt.items.map((i) => i.toJson()).toList(),
        }
      });
    } catch (_) {}

    // Clear state after we stored it locally.
    state = ReceiptEntryState();

    // Update the home widget summary using all receipts we have in this session.
    await _updateWidgetSummaryFromStore();

    // Always report success for local/session save; log/handle apiOk as needed later.
    return true;
  }

  Future<void> _updateWidgetSummaryFromStore() async {
    final receiptsAsync = _ref.read(receiptsStoreProvider);
    final receipts = receiptsAsync.valueOrNull ?? [];
    
    if (receipts.isEmpty) {
      await saveAndUpdateWidgetSummary(WidgetSummary(
        totalThisMonth: 0,
        topStore: '—',
        updatedAt: DateTime.now(),
      ));
      return;
    }

    final now = DateTime.now();
    final currentMonth = receipts
        .where((r) => r.date.year == now.year && r.date.month == now.month)
        .toList();

    final totalThisMonth =
        currentMonth.fold<double>(0.0, (sum, r) => sum + r.total);

    String topStore = '—';
    double topStoreTotal = 0.0;
    for (final r in currentMonth) {
      final tally = currentMonth
          .where((x) => x.store == r.store)
          .fold<double>(0.0, (sum, x) => sum + x.total);
      if (tally > topStoreTotal) {
        topStoreTotal = tally;
        topStore = r.store;
      }
    }

    await saveAndUpdateWidgetSummary(WidgetSummary(
      totalThisMonth: totalThisMonth,
      topStore: topStore,
      updatedAt: DateTime.now(),
    ));
  }
  
  void clearResult() {
    state = ReceiptEntryState();
  }
}
