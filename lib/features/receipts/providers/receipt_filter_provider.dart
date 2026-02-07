import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisabi/core/models/receipt_model.dart';
import 'package:hisabi/core/models/category_model.dart';
import 'package:hisabi/features/receipts/providers/receipts_store.dart';

class ReceiptFilters {
  final String? searchQuery;
  final ExpenseCategory? categoryFilter;
  final DateTime? startDate;
  final DateTime? endDate;
  final double? minAmount;
  final double? maxAmount;
  final String? storeFilter;

  ReceiptFilters({
    this.searchQuery,
    this.categoryFilter,
    this.startDate,
    this.endDate,
    this.minAmount,
    this.maxAmount,
    this.storeFilter,
  });

  ReceiptFilters copyWith({
    String? searchQuery,
    ExpenseCategory? categoryFilter,
    DateTime? startDate,
    DateTime? endDate,
    double? minAmount,
    double? maxAmount,
    String? storeFilter,
    bool clearSearchQuery = false,
    bool clearCategoryFilter = false,
    bool clearStartDate = false,
    bool clearEndDate = false,
    bool clearMinAmount = false,
    bool clearMaxAmount = false,
    bool clearStoreFilter = false,
  }) {
    return ReceiptFilters(
      searchQuery: clearSearchQuery ? null : (searchQuery ?? this.searchQuery),
      categoryFilter: clearCategoryFilter ? null : (categoryFilter ?? this.categoryFilter),
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      minAmount: clearMinAmount ? null : (minAmount ?? this.minAmount),
      maxAmount: clearMaxAmount ? null : (maxAmount ?? this.maxAmount),
      storeFilter: clearStoreFilter ? null : (storeFilter ?? this.storeFilter),
    );
  }

  bool get hasFilters => 
    searchQuery != null && searchQuery!.isNotEmpty ||
    categoryFilter != null ||
    startDate != null ||
    endDate != null ||
    minAmount != null ||
    maxAmount != null ||
    (storeFilter != null && storeFilter!.isNotEmpty);

  void clear() {
    // This is a data class, so clearing means creating a new instance
  }
}

final receiptFiltersProvider = StateProvider<ReceiptFilters>((ref) => ReceiptFilters());

final filteredReceiptsProvider = FutureProvider.autoDispose<List<ReceiptModel>>((ref) async {
  final receiptsAsync = ref.watch(receiptsStoreProvider);
  final filters = ref.watch(receiptFiltersProvider);
  
  final receipts = receiptsAsync.valueOrNull ?? [];
  
  if (!filters.hasFilters) {
    return receipts;
  }

  var filtered = receipts;

  if (filters.searchQuery != null && filters.searchQuery!.isNotEmpty) {
    final query = filters.searchQuery!.toLowerCase();
    filtered = filtered.where((r) {
      return r.store.toLowerCase().contains(query) ||
          r.name.toLowerCase().contains(query) ||
          r.items.any((item) => item.name.toLowerCase().contains(query));
    }).toList();
  }

  if (filters.categoryFilter != null) {
    filtered = filtered.where((r) {
      return r.items.any((item) => item.category == filters.categoryFilter) ||
          r.primaryCategory == filters.categoryFilter;
    }).toList();
  }

  if (filters.startDate != null) {
    filtered = filtered.where((r) => !r.date.isBefore(filters.startDate!)).toList();
  }

  if (filters.endDate != null) {
    filtered = filtered.where((r) => !r.date.isAfter(filters.endDate!)).toList();
  }

  if (filters.minAmount != null) {
    filtered = filtered.where((r) => r.total >= filters.minAmount!).toList();
  }

  if (filters.maxAmount != null) {
    filtered = filtered.where((r) => r.total <= filters.maxAmount!).toList();
  }

  if (filters.storeFilter != null && filters.storeFilter!.isNotEmpty) {
    final storeQuery = filters.storeFilter!.toLowerCase();
    filtered = filtered.where((r) => r.store.toLowerCase().contains(storeQuery)).toList();
  }

  return filtered;
});

