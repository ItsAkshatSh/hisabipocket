import 'package:hive_flutter/hive_flutter.dart';
import 'package:hisabi/core/models/receipt_model.dart';
import 'package:hisabi/core/models/category_model.dart';
import 'package:hisabi/features/settings/providers/settings_provider.dart';
import 'package:hisabi/features/financial_profile/models/financial_profile_model.dart';

class StorageService {
  static const String _receiptsBoxName = 'receipts';
  static const String _settingsBoxName = 'settings';
  static const String _authBoxName = 'auth';
  static const String _financialProfileBoxName = 'financial_profile';
  
  // Store current user email to track data ownership
  static String? _currentUserEmail;
  
  static Future<void> init() async {
    try {
      await Hive.initFlutter();
      await Hive.openBox(_receiptsBoxName);
      await Hive.openBox(_settingsBoxName);
      await Hive.openBox(_authBoxName);
      await Hive.openBox(_financialProfileBoxName);
      print('Storage initialized successfully');
    } catch (e) {
      print('Error initializing storage: $e');
      rethrow;
    }
  }
  
  // Initialize user-specific storage and clear old data if user changed
  static Future<void> initializeUserStorage(String userEmail) async {
    final box = await Hive.openBox(_receiptsBoxName);
    final storedUserEmail = box.get('_user_email') as String?;
    
    // If different user, clear old data
    if (storedUserEmail != null && storedUserEmail != userEmail) {
      print('Different user detected. Clearing old data for: $storedUserEmail');
      await box.clear();
      final settingsBox = await Hive.openBox(_settingsBoxName);
      await settingsBox.clear();
      final profileBox = await Hive.openBox(_financialProfileBoxName);
      await profileBox.clear();
    }
    
    // Store current user email
    await box.put('_user_email', userEmail);
    await box.flush();
    _currentUserEmail = userEmail;
    print('User storage initialized for: $userEmail');
  }

  static Future<void> saveReceipts(List<ReceiptModel> receipts) async {
    try {
      if (_currentUserEmail == null) {
        throw Exception('User storage not initialized. Call initializeUserStorage first.');
      }
      final box = await Hive.openBox(_receiptsBoxName);
      final receiptsJson = receipts.map((r) => _receiptToJson(r)).toList();
      await box.put('receipts_list', receiptsJson);
      await box.put('_user_email', _currentUserEmail);
      await box.flush();
      print('Saved ${receipts.length} receipts to storage for user: $_currentUserEmail');
    } catch (e) {
      print('Error saving receipts: $e');
      rethrow;
    }
  }

  static Future<List<ReceiptModel>> loadReceipts() async {
    try {
      if (_currentUserEmail == null) {
        print('User storage not initialized. Returning empty receipts.');
        return [];
      }
      final box = await Hive.openBox(_receiptsBoxName);
      final storedUserEmail = box.get('_user_email') as String?;
      
      // Verify data belongs to current user
      if (storedUserEmail != _currentUserEmail) {
        print('Receipts belong to different user. Returning empty list.');
        return [];
      }
      
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
      print('Loading ${receiptsList.length} receipts from storage for user: $_currentUserEmail');
      
      final loadedReceipts = receiptsList
          .map((item) {
            try {
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

  static Future<void> saveSettings(SettingsState settings) async {
    try {
      if (_currentUserEmail == null) {
        throw Exception('User storage not initialized. Call initializeUserStorage first.');
      }
      final box = await Hive.openBox(_settingsBoxName);
      await box.put('currency', settings.currency.name);
      await box.put('namingFormat', settings.namingFormat.name);
      await box.put('themeMode', settings.themeMode.name);
      await box.put('widgetSettings', settings.widgetSettings.toJson());
      await box.put('_user_email', _currentUserEmail);
      await box.flush();
      print('Settings saved for user: $_currentUserEmail');
    } catch (e) {
      print('Error saving settings: $e');
      rethrow;
    }
  }

  static Future<SettingsState> loadSettings() async {
    try {
      if (_currentUserEmail == null) {
        print('User storage not initialized. Returning default settings.');
        return SettingsState();
      }
      final box = await Hive.openBox(_settingsBoxName);
      final storedUserEmail = box.get('_user_email') as String?;
      
      // Verify data belongs to current user
      if (storedUserEmail != _currentUserEmail) {
        print('Settings belong to different user. Returning default settings.');
        return SettingsState();
      }
      
      final currencyName = box.get('currency') as String?;
      final namingFormatName = box.get('namingFormat') as String?;
      final themeModeName = box.get('themeMode') as String?;
      
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
      
      final themeMode = themeModeName != null
          ? AppThemeMode.values.firstWhere(
              (t) => t.name == themeModeName,
              orElse: () => AppThemeMode.dark,
            )
          : AppThemeMode.dark;
      
      final widgetSettingsData = box.get('widgetSettings');
      final widgetSettings = widgetSettingsData != null
          ? WidgetSettings.fromJson(Map<String, dynamic>.from(widgetSettingsData))
          : WidgetSettings();
      
      print('Settings loaded for user: $_currentUserEmail');
      return SettingsState(
        currency: currency,
        namingFormat: namingFormat,
        themeMode: themeMode,
        widgetSettings: widgetSettings,
      );
    } catch (e) {
      return SettingsState();
    }
  }

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
              ?.map((item) {
                final categoryName = item['category'] as String?;
                final category = categoryName != null
                    ? ExpenseCategory.values.firstWhere(
                        (c) => c.name == categoryName,
                        orElse: () => ExpenseCategory.other,
                      )
                    : null;
                return ReceiptItem(
                  name: item['name'] as String? ?? '',
                  quantity: (item['quantity'] as num?)?.toDouble() ?? 0.0,
                  price: (item['price'] as num?)?.toDouble() ?? 0.0,
                  total: (item['total'] as num?)?.toDouble() ?? 0.0,
                  category: category,
                );
              })
              .toList() ??
          [],
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
    );
  }

  static Future<void> saveAuthState(String email, String name, String? pictureUrl) async {
    final box = await Hive.openBox(_authBoxName);
    await box.put('email', email);
    await box.put('name', name);
    await box.put('pictureUrl', pictureUrl ?? '');
    await box.put('isAuthenticated', true);
    // Initialize user storage when auth state is saved
    await initializeUserStorage(email);
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
    _currentUserEmail = null;
    print('Auth state cleared');
  }

  static Future<void> saveFinancialProfile(FinancialProfile profile) async {
    try {
      if (_currentUserEmail == null) {
        throw Exception('User storage not initialized. Call initializeUserStorage first.');
      }
      final box = await Hive.openBox(_financialProfileBoxName);
      await box.put('profile', profile.toJson());
      await box.put('_user_email', _currentUserEmail);
      await box.flush();
      print('Financial profile saved for user: $_currentUserEmail');
    } catch (e) {
      print('Error saving financial profile: $e');
      rethrow;
    }
  }

  static Future<FinancialProfile> loadFinancialProfile() async {
    try {
      if (_currentUserEmail == null) {
        print('User storage not initialized. Returning default profile.');
        return FinancialProfile();
      }
      final box = await Hive.openBox(_financialProfileBoxName);
      final storedUserEmail = box.get('_user_email') as String?;

      // Verify data belongs to current user
      if (storedUserEmail != _currentUserEmail) {
        print('Financial profile belongs to different user. Returning default profile.');
        return FinancialProfile();
      }

      final profileData = box.get('profile');
      if (profileData == null) {
        print('No financial profile found in storage');
        return FinancialProfile();
      }

      print('Financial profile loaded for user: $_currentUserEmail');
      return FinancialProfile.fromJson(Map<String, dynamic>.from(profileData));
    } catch (e) {
      print('Error loading financial profile: $e');
      return FinancialProfile();
    }
  }

  static Future<void> clearAll() async {
    await Hive.deleteBoxFromDisk(_receiptsBoxName);
    await Hive.deleteBoxFromDisk(_settingsBoxName);
    await Hive.deleteBoxFromDisk(_authBoxName);
    await Hive.deleteBoxFromDisk(_financialProfileBoxName);
    _currentUserEmail = null;
    print('All data cleared');
  }
}

