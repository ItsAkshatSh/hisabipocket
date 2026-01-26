import 'package:hisabi/core/models/category_model.dart';
import 'package:hisabi/features/receipts/models/receipt_split_model.dart';
import 'package:hisabi/features/settings/providers/settings_provider.dart';

class ReceiptItem {
  final String name;
  final double quantity;
  final double price;
  final double total;
  final ExpenseCategory? category;

  ReceiptItem({
    required this.name,
    required this.quantity,
    required this.price,
    required this.total,
    this.category,
  });

  ReceiptItem copyWith({
    String? name,
    double? quantity,
    double? price,
    double? total,
    ExpenseCategory? category,
  }) {
    return ReceiptItem(
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
      total: total ?? this.total,
      category: category ?? this.category,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'quantity': quantity,
    'price': price,
    'total': total,
    'category': category?.name,
  };
  
  factory ReceiptItem.fromJson(Map<String, dynamic> json) {
    return ReceiptItem(
      name: json['name'],
      quantity: (json['quantity'] as num).toDouble(),
      price: (json['price'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      category: json['category'] != null
          ? ExpenseCategory.values.firstWhere(
              (c) => c.name == json['category'],
              orElse: () => ExpenseCategory.other,
            )
          : null,
    );
  }
}

class ReceiptModel {
  final String id; // Use String for IDs in general for backend safety
  final String name;
  final DateTime date;
  final String store;
  final List<ReceiptItem> items;
  final double total;
  final ExpenseCategory? primaryCategory;
  final List<ReceiptSplit> splits;
  final Currency currency;

  ReceiptModel({
    required this.id,
    required this.name,
    required this.date,
    required this.store,
    required this.items,
    required this.total,
    this.primaryCategory,
    List<ReceiptSplit>? splits,
    Currency? currency,
  })  : splits = splits ?? [],
        currency = currency ?? Currency.USD;

  bool get isSplit => splits.isNotEmpty;
  
  double get splitTotal => splits.fold(0.0, (sum, split) => sum + split.amount);
  
  double get remainingAmount => total - splitTotal;
  
  // Calculate primary category from items
  ExpenseCategory? get calculatedPrimaryCategory {
    if (items.isEmpty) return null;
    final categoryCounts = <ExpenseCategory, int>{};
    for (final item in items) {
      if (item.category != null) {
        categoryCounts[item.category!] = (categoryCounts[item.category!] ?? 0) + 1;
      }
    }
    if (categoryCounts.isEmpty) return null;
    return categoryCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  // Factory constructor for full detail
  factory ReceiptModel.fromDetailJson(Map<String, dynamic> json) {
    return ReceiptModel(
      id: json['id'],
      name: json['name'],
      date: DateTime.parse(json['data']['date']),
      store: json['data']['store'],
      items: (json['data']['items'] as List)
          .map((i) => ReceiptItem(
              name: i['name'], 
              quantity: i['quantity'].toDouble(), 
              price: i['price'].toDouble(), 
              total: i['total'].toDouble()
          )).toList(),
      total: json['data']['total'].toDouble(),
    );
  }
}
