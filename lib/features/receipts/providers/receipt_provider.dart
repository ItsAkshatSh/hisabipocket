import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisabi/core/models/receipt_model.dart';
import 'package:hisabi/core/services/ai_service.dart';
import 'package:hisabi/core/services/receipt_ocr_service.dart';
import 'package:hisabi/features/receipts/providers/receipts_store.dart';
import 'package:hisabi/features/settings/providers/settings_provider.dart';

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
  return ReceiptEntryNotifier(ref);
});

class ReceiptEntryNotifier extends StateNotifier<ReceiptEntryState> {
  final Ref _ref;
  final ReceiptOCRService _ocrService = ReceiptOCRService();

  ReceiptEntryNotifier(this._ref) : super(ReceiptEntryState());

  Future<void> analyzeImage(File imageFile) async {
    state = state.copyWith(isAnalyzing: true, analysisError: null);
    
    try {
      final settingsAsync = _ref.read(settingsProvider);
      final currency = settingsAsync.valueOrNull?.currency ?? Currency.USD;
      final receipt = await _ocrService.processReceipt(imageFile, currency: currency);
      if (receipt != null) {
        state = state.copyWith(
          analyzedReceipt: receipt,
          isAnalyzing: false,
        );
      } else {
        state = state.copyWith(
          isAnalyzing: false,
          analysisError: 'Failed to extract data from receipt. Please try again or enter manually.',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isAnalyzing: false,
        analysisError: 'OCR Analysis failed: $e',
      );
    }
  }

  void setManualReceipt(ReceiptModel receipt) {
    state = state.copyWith(analyzedReceipt: receipt);
  }

  Future<bool> saveReceipt(String name, ReceiptModel receipt) async {
    try {
      // 1. Auto-categorize items if not already categorized
      final categorizedReceipt = await _categorizeReceiptItems(receipt);
      
      // 2. Final receipt with the user-provided name
      final finalReceipt = ReceiptModel(
        id: receipt.id,
        name: name, // Use the name from the modal
        date: receipt.date,
        store: receipt.store,
        items: categorizedReceipt.items,
        total: receipt.total,
        primaryCategory: categorizedReceipt.primaryCategory,
        currency: receipt.currency,
        splits: receipt.splits,
      );

      // 3. Add to store (which handles persistent storage and UI update)
      await _ref.read(receiptsStoreProvider.notifier).add(finalReceipt);

      // 4. Force a refresh of dashboard providers and receipts
      _ref.invalidate(receiptsStoreProvider);
      await _ref.read(receiptsStoreProvider.notifier).refresh();

      state = ReceiptEntryState();
      return true;
    } catch (e) {
      print('Error saving receipt: $e');
      return false;
    }
  }
  
  Future<ReceiptModel> _categorizeReceiptItems(ReceiptModel receipt) async {
    final allCategorized = receipt.items.every((item) => item.category != null);
    if (allCategorized) return receipt;
    
    try {
      final aiService = AIService();
      final itemNames = receipt.items.map((i) => i.name).toList();
      final categorizations = await aiService.categorizeItems(
        itemNames: itemNames,
        storeName: receipt.store,
        totalAmount: receipt.total,
      );
      
      final categorizedItems = receipt.items.map((item) {
        final category = categorizations[item.name] ?? item.category;
        return item.copyWith(category: category);
      }).toList();
      
      return ReceiptModel(
        id: receipt.id,
        name: receipt.name,
        date: receipt.date,
        store: receipt.store,
        items: categorizedItems,
        total: receipt.total,
        currency: receipt.currency,
        splits: receipt.splits,
      );
    } catch (e) {
      print('Error categorizing items: $e');
      return receipt;
    }
  }

  void clearResult() {
    state = ReceiptEntryState();
  }
}

final receiptProvider = StateNotifierProvider<ReceiptNotifier, void>((ref) {
  return ReceiptNotifier(ref);
});

class ReceiptNotifier extends StateNotifier<void> {
  final Ref _ref;
  
  ReceiptNotifier(this._ref) : super(null);

  Future<void> updateReceipt(ReceiptModel receipt) async {
    await _ref.read(receiptsStoreProvider.notifier).update(receipt);
    _ref.invalidate(receiptsStoreProvider);
    await _ref.read(receiptsStoreProvider.notifier).refresh();
  }
}