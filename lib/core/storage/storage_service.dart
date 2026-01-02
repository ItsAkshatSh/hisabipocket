import 'package:hive_flutter/hive_flutter.dart';
import 'package:hisabi/core/models/receipt_model.dart';
import 'package:hisabi/features/settings/providers/settings_provider.dart';

class StorageService {
  static const String _receiptsBoxName = 'receipts';
  static const String _settingsBoxName = 'settings';
  static const String _authBoxName = 'auth';
  
  static Future<void> init() async {
    try {
      await Hive.initFlutter();
      
      // Pre-open boxes to ensure they're ready
      await Hive.openBox(_receiptsBoxName);
      await Hive.openBox(_settingsBoxName);
      await Hive.openBox(_authBoxName);
      
      print('Storage initialized successfully');
    } catch (e) {
      print('Error initializing storage: $e');
      rethrow;
    }
  }

  // Receipts storage
  static Future<void> saveReceipts(List<ReceiptModel> receipts) async {
    try {
      final box = await Hive.openBox(_receiptsBoxName);
      final receiptsJson = receipts.map((r) => _receiptToJson(r)).toList();
      await box.put('receipts_list', receiptsJson);
      // Force write to disk
      await box.flush();
      print('Saved ${receipts.length} receipts to storage');
    } catch (e) {
      print('Error saving receipts: $e');
      rethrow;
    }
  }

  static Future<List<ReceiptModel>> loadReceipts() async {
    try {
      final box = await Hive.openBox(_receiptsBoxName);
      final receiptsData = box.get('receipts_list');
      
      if (receiptsData == null) {
        print('No receipts found in storage');
        return [];
      }
      
      // Hive returns List<dynamic>, so we need to cast properly
      if (receiptsData is! List) {
        print('Receipts data is not a list: ${receiptsData.runtimeType}');
        return [];
      }
      
      final receiptsList = receiptsData;
      print('Loading ${receiptsList.length} receipts from storage');
      
      final loadedReceipts = receiptsList
          .map((item) {
            try {
              // Ensure item is a Map
              if (item is Map) {
                return _receiptFromJson(Map<String, dynamic>.from(item));
              }
              print('Receipt item is not a Map: ${item.runtimeType}');
              return null;
            } catch (e) {
              print('Error parsing receipt item: $e');
              return null;
            }
          })
          .whereType<ReceiptModel>()
          .toList();
      
      print('Successfully loaded ${loadedReceipts.length} receipts');
      return loadedReceipts;
    } catch (e, stackTrace) {
      print('Error loading receipts: $e');
      print('Stack trace: $stackTrace');
      return [];
    }
  }

  static Future<void> addReceipt(ReceiptModel receipt) async {
    try {
      final receipts = await loadReceipts();
      receipts.add(receipt);
      await saveReceipts(receipts);
      
      // Verify the receipt was saved
      final verifyReceipts = await loadReceipts();
      if (verifyReceipts.length != receipts.length) {
        throw Exception('Receipt was not saved correctly. Expected ${receipts.length}, got ${verifyReceipts.length}');
      }
      print('Receipt added and verified successfully');
    } catch (e) {
      print('Error adding receipt: $e');
      rethrow;
    }
  }

  static Future<void> deleteReceipt(String receiptId) async {
    final receipts = await loadReceipts();
    receipts.removeWhere((r) => r.id == receiptId);
    await saveReceipts(receipts);
  }

  // Settings storage
  static Future<void> saveSettings(SettingsState settings) async {
    try {
      final box = await Hive.openBox(_settingsBoxName);
      await box.put('currency', settings.currency.name);
      await box.put('namingFormat', settings.namingFormat.name);
      // Force write to disk
      await box.flush();
    } catch (e) {
      print('Error saving settings: $e');
      rethrow;
    }
  }

  static Future<SettingsState> loadSettings() async {
    try {
      final box = await Hive.openBox(_settingsBoxName);
      final currencyName = box.get('currency') as String?;
      final namingFormatName = box.get('namingFormat') as String?;
      
      final currency = currencyName != null
          ? Currency.values.firstWhere(
              (c) => c.name == currencyName,
              orElse: () => Currency.USD,
            )
          : Currency.USD;
      
      final namingFormat = namingFormatName != null
          ? NamingFormat.values.firstWhere(
              (f) => f.name == namingFormatName,
              orElse: () => NamingFormat.storeDate,
            )
          : NamingFormat.storeDate;
      
      return SettingsState(
        currency: currency,
        namingFormat: namingFormat,
      );
    } catch (e) {
      return SettingsState();
    }
  }

  // Helper methods for receipt serialization
  static Map<String, dynamic> _receiptToJson(ReceiptModel receipt) {
    return {
      'id': receipt.id,
      'name': receipt.name,
      'date': receipt.date.toIso8601String(),
      'store': receipt.store,
      'items': receipt.items.map((item) => item.toJson()).toList(),
      'total': receipt.total,
    };
  }

  static ReceiptModel _receiptFromJson(Map<String, dynamic> json) {
    return ReceiptModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      store: json['store'] as String? ?? '',
      items: (json['items'] as List?)
              ?.map((item) => ReceiptItem(
                    name: item['name'] as String? ?? '',
                    quantity: (item['quantity'] as num?)?.toDouble() ?? 0.0,
                    price: (item['price'] as num?)?.toDouble() ?? 0.0,
                    total: (item['total'] as num?)?.toDouble() ?? 0.0,
                  ))
              .toList() ??
          [],
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
    );
  }

  // Auth storage
  static Future<void> saveAuthState(String email, String name, String? pictureUrl) async {
    final box = await Hive.openBox(_authBoxName);
    await box.put('email', email);
    await box.put('name', name);
    await box.put('pictureUrl', pictureUrl ?? '');
    await box.put('isAuthenticated', true);
  }

  static Future<Map<String, dynamic>?> loadAuthState() async {
    try {
      final box = await Hive.openBox(_authBoxName);
      final isAuthenticated = box.get('isAuthenticated') as bool? ?? false;
      
      if (!isAuthenticated) {
        return null;
      }
      
      return {
        'email': box.get('email') as String? ?? '',
        'name': box.get('name') as String? ?? '',
        'pictureUrl': box.get('pictureUrl') as String?,
      };
    } catch (e) {
      return null;
    }
  }

  static Future<void> clearAuthState() async {
    final box = await Hive.openBox(_authBoxName);
    await box.clear();
  }

  // Clear all data (useful for logout or reset)
  static Future<void> clearAll() async {
    await Hive.deleteBoxFromDisk(_receiptsBoxName);
    await Hive.deleteBoxFromDisk(_settingsBoxName);
    await Hive.deleteBoxFromDisk(_authBoxName);
  }
}

