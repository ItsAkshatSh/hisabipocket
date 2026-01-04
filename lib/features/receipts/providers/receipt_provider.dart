import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisabi/core/api/api_client.dart';
import 'package:hisabi/core/models/receipt_model.dart';
import 'package:hisabi/features/auth/providers/auth_provider.dart';
import 'package:hisabi/core/widgets/widget_summary.dart';
import 'package:hisabi/features/receipts/providers/receipts_store.dart';

final receiptDetailsProvider = FutureProvider.autoDispose.family<ReceiptModel, String>((ref, receiptId) async {
  final receiptsAsync = ref.read(receiptsStoreProvider);
  final receipts = receiptsAsync.valueOrNull ?? [];
  
  try {
    final receipt = receipts.firstWhere((r) => r.id == receiptId);
    return receipt;
  } catch (e) {
    throw Exception('Receipt not found');
  }
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

  Future<void> analyzeImage(File imageFile) async {
    state = state.copyWith(isAnalyzing: true, analysisError: null);
    
    try {
      state = state.copyWith(
        isAnalyzing: false,
        analysisError: 'Receipt image analysis is not yet implemented. Please use manual entry.',
      );
    } catch (e) {
      state = state.copyWith(
        isAnalyzing: false,
        analysisError: 'AI Analysis failed. Try manual entry.',
      );
    }
  }

  void setManualReceipt(ReceiptModel receipt) {
    state = state.copyWith(analyzedReceipt: receipt);
  }

  Future<bool> saveReceipt(String name, ReceiptModel receipt) async {
    _ref.read(receiptsStoreProvider.notifier).add(receipt);

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

    state = ReceiptEntryState();
    await _updateWidgetSummaryFromStore();
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
