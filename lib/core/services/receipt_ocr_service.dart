import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hisabi/core/models/receipt_model.dart';

class ReceiptOCRService {
  static String get _clientId => dotenv.get('VERYFI_CLIENT_ID', fallback: '');
  static String get _apiKey => dotenv.get('VERYFI_API_KEY', fallback: '');
  static const String _baseUrl = 'https://api.veryfi.com/api/v8/partner/documents';

  Future<ReceiptModel?> processReceipt(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'CLIENT-ID': _clientId,
          'AUTHORIZATION': _apiKey,
        },
        body: jsonEncode({
          'file_data': base64Image,
          'file_name': 'receipt.jpg',
          'categories': [],
          'tags': [],
          'compute': true,
          'country': 'BD',
          'document_type': 'receipt'
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return _mapVeryfiToReceipt(data);
      } else {
        print('Veryfi error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('OCR processing error: $e');
    }
    return null;
  }

  ReceiptModel _mapVeryfiToReceipt(Map<String, dynamic> data) {
    final items = (data['line_items'] as List? ?? []).map((item) {
      return ReceiptItem(
        name: item['description'] ?? 'Unknown Item',
        quantity: (item['quantity'] ?? 1.0).toDouble(),
        price: (item['price'] ?? 0.0).toDouble(),
        total: (item['total'] ?? 0.0).toDouble(),
      );
    }).toList();

    return ReceiptModel(
      id: data['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: data['vendor']?['name'] ?? 'New Receipt',
      date: DateTime.tryParse(data['date'] ?? '') ?? DateTime.now(),
      store: data['vendor']?['name'] ?? 'Unknown Store',
      items: items,
      total: (data['total'] ?? 0.0).toDouble(),
    );
  }
}
