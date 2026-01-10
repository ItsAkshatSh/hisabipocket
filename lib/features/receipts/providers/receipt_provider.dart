import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisabi/core/models/receipt_model.dart';
import 'package:hisabi/core/services/ai_service.dart';
import 'package:hisabi/core/widgets/widget_summary.dart';
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

  ReceiptEntryNotifier(this._ref) : super(ReceiptEntryState());

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
    // Auto-categorize items if not already categorized
    final categorizedReceipt = await _categorizeReceiptItems(receipt);
    
    _ref.read(receiptsStoreProvider.notifier).add(categorizedReceipt);

    // API call removed - data is now saved to Firebase via receiptsStoreProvider
    // If you need to sync to a backend API, add it here

    state = ReceiptEntryState();
    await _updateWidgetSummaryFromStore();
    return true;
  }
  
  Future<ReceiptModel> _categorizeReceiptItems(ReceiptModel receipt) async {
    // Check if items are already categorized
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
      );
    } catch (e) {
      print('Error categorizing items: $e');
      // Return original receipt if categorization fails
      return receipt;
    }
  }

  Future<void> _updateWidgetSummaryFromStore() async {
    final receiptsAsync = _ref.read(receiptsStoreProvider);
    final receipts = receiptsAsync.valueOrNull ?? [];
    
    // Get settings for currency and widget settings
    final settingsAsync = _ref.read(settingsProvider);
    final settings = settingsAsync.valueOrNull;
    final currencyCode = settings?.currency.name ?? 'USD';
    final widgetSettings = settings?.widgetSettings;
    
    if (receipts.isEmpty) {
      await saveAndUpdateWidgetSummary(
        WidgetSummary(
          totalThisMonth: 0,
          topStore: '—',
          receiptsCount: 0,
          averagePerReceipt: 0.0,
          daysWithExpenses: 0,
          totalItems: 0,
          updatedAt: DateTime.now(),
        ),
        currencyCode: currencyCode,
        widgetSettings: widgetSettings?.toJson(),
      );
      return;
    }

    final now = DateTime.now();
    final currentMonth = receipts
        .where((r) => r.date.year == now.year && r.date.month == now.month)
        .toList();

    final totalThisMonth =
        currentMonth.fold<double>(0.0, (sum, r) => sum + r.total);
    final receiptsCount = currentMonth.length;
    final averagePerReceipt = receiptsCount > 0 ? totalThisMonth / receiptsCount : 0.0;
    
    final daysWithExpenses = currentMonth
        .map((r) => DateTime(r.date.year, r.date.month, r.date.day))
        .toSet()
        .length;
    
    final totalItems = currentMonth.fold<int>(0, (sum, r) => sum + r.items.length);

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

    await saveAndUpdateWidgetSummary(
      WidgetSummary(
        totalThisMonth: totalThisMonth,
        topStore: topStore,
        receiptsCount: receiptsCount,
        averagePerReceipt: averagePerReceipt,
        daysWithExpenses: daysWithExpenses,
        totalItems: totalItems,
        updatedAt: DateTime.now(),
      ),
      currencyCode: currencyCode,
      widgetSettings: widgetSettings?.toJson(),
    );
  }
  
  void clearResult() {
    state = ReceiptEntryState();
  }
}
