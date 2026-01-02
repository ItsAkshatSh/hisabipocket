class ReceiptItem {
  final String name;
  final double quantity;
  final double price;
  final double total;

  ReceiptItem({required this.name, required this.quantity, required this.price, required this.total});

  Map<String, dynamic> toJson() => {
    'name': name,
    'quantity': quantity,
    'price': price,
    'total': total,
  };
}

class ReceiptModel {
  final String id; // Use String for IDs in general for backend safety
  final String name;
  final DateTime date;
  final String store;
  final List<ReceiptItem> items;
  final double total;

  ReceiptModel({
    required this.id, required this.name, required this.date, 
    required this.store, required this.items, required this.total
  });

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
