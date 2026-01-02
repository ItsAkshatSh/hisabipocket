class ReceiptSummaryModel {
  final String id;
  final String name;
  final DateTime savedAt;
  final double total;
  final int itemCount;
  final String store;

  ReceiptSummaryModel({
    required this.id, required this.name, required this.savedAt, 
    required this.total, required this.itemCount, required this.store
  });

  factory ReceiptSummaryModel.fromJson(Map<String, dynamic> json) {
    return ReceiptSummaryModel(
      id: json['id'],
      name: json['name'],
      savedAt: DateTime.parse(json['saved_at']),
      total: json['total'].toDouble(),
      itemCount: json['item_count'],
      store: json['store'],
    );
  }
}
