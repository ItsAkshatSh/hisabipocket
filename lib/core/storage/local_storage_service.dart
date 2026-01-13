import 'package:hive_flutter/hive_flutter.dart';
import 'package:hisabi/core/models/receipt_model.dart';
import 'package:hisabi/core/models/category_model.dart';
import 'package:hisabi/features/settings/providers/settings_provider.dart';
import 'package:hisabi/features/financial_profile/models/financial_profile_model.dart';

class LocalStorageService {
  static const String _receiptsBoxName = 'receipts';
  static const String _settingsBoxName = 'settings';
  static const String _financialProfileBoxName = 'financialProfile';
  static const String _authBoxName = 'auth';

  static Box? _receiptsBox;
  static Box? _settingsBox;
  static Box? _financialProfileBox;
  static Box? _authBox;

  static String? _currentUserEmail;

  static Future<void> init() async {
    try {
      await Hive.initFlutter();
      
      _receiptsBox = await Hive.openBox(_receiptsBoxName);
      _settingsBox = await Hive.openBox(_settingsBoxName);
      _financialProfileBox = await Hive.openBox(_financialProfileBoxName);
      _authBox = await Hive.openBox(_authBoxName);
      
      // Load current user from auth box
      final userData = _authBox?.get('user') as Map<String, dynamic>?;
      if (userData != null && userData['email'] != null) {
        _currentUserEmail = userData['email'] as String;
        _authBox?.put('currentUserEmail', _currentUserEmail);
      } else {
        _currentUserEmail = _authBox?.get('currentUserEmail') as String?;
      }
      
      // If no user exists, set default user email
      if (_currentUserEmail == null) {
        _currentUserEmail = 'user@example.com';
        _authBox?.put('currentUserEmail', _currentUserEmail);
      }
      
      print('✅ Local storage initialized');
    } catch (e) {
      print('❌ Error initializing local storage: $e');
      // Set default user even if initialization fails
      _currentUserEmail = 'user@example.com';
    }
  }

  static String? get currentUserEmail => _currentUserEmail;

  static void _setCurrentUser(String email) {
    _currentUserEmail = email;
    _authBox?.put('currentUserEmail', email);
  }

  static String _getUserKey(String? userEmail, String key) {
    final email = userEmail ?? _currentUserEmail ?? 'default';
    return '$email:$key';
  }

  static Future<void> saveReceipts(List<ReceiptModel> receipts) async {
    if (_receiptsBox == null) {
      throw Exception('Storage not initialized');
    }

    try {
      final receiptsJson = receipts.map((r) => _receiptToJson(r)).toList();
      final key = _getUserKey(_currentUserEmail, 'receipts');
      await _receiptsBox!.put(key, receiptsJson);
      
      print('✅ Saved ${receipts.length} receipts locally');
    } catch (e, stackTrace) {
      print('❌ Error saving receipts: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  static Future<List<ReceiptModel>> loadReceipts({String? userEmail}) async {
    if (_receiptsBox == null) {
      print('Storage not initialized. Returning empty receipts.');
      return [];
    }

    try {
      final key = _getUserKey(userEmail ?? _currentUserEmail, 'receipts');
      final receiptsData = _receiptsBox!.get(key) as List?;
      
      if (receiptsData == null) {
        print('No receipts found locally');
        return [];
      }

      final loadedReceipts = receiptsData
          .map((item) {
            try {
              if (item is Map) {
                return _receiptFromJson(Map<String, dynamic>.from(item));
              }
              return null;
            } catch (e) {
              print('Error parsing receipt item: $e');
              return null;
            }
          })
          .whereType<ReceiptModel>()
          .toList();

      print('Successfully loaded ${loadedReceipts.length} receipts from local storage');
      return loadedReceipts;
    } catch (e) {
      print('Error loading receipts: $e');
      return [];
    }
  }

  static Future<void> addReceipt(ReceiptModel receipt) async {
    if (_receiptsBox == null) {
      throw Exception('Storage not initialized');
    }

    try {
      final key = _getUserKey(_currentUserEmail, 'receipts');
      final receiptsData = _receiptsBox!.get(key) as List? ?? [];
      
      final receiptJson = _receiptToJson(receipt);
      receiptsData.add(receiptJson);
      
      await _receiptsBox!.put(key, receiptsData);
      
      print('✅ Receipt added locally');
    } catch (e, stackTrace) {
      print('❌ Error adding receipt: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  static Future<void> deleteReceipt(String receiptId) async {
    if (_receiptsBox == null) {
      throw Exception('Storage not initialized');
    }

    try {
      final key = _getUserKey(_currentUserEmail, 'receipts');
      final receiptsData = _receiptsBox!.get(key) as List? ?? [];
      
      receiptsData.removeWhere((item) {
        if (item is Map) {
          return (item['id'] as String?) == receiptId;
        }
        return false;
      });
      
      await _receiptsBox!.put(key, receiptsData);
      
      print('✅ Receipt deleted locally');
    } catch (e, stackTrace) {
      print('❌ Error deleting receipt: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  static Future<void> saveSettings(SettingsState settings, {String? userEmail}) async {
    if (_settingsBox == null) {
      throw Exception('Storage not initialized');
    }

    try {
      final key = _getUserKey(userEmail ?? _currentUserEmail, 'settings');
      await _settingsBox!.put(key, {
        'currency': settings.currency.name,
        'namingFormat': settings.namingFormat.name,
        'themeMode': settings.themeMode.name,
        'widgetSettings': settings.widgetSettings.toJson(),
      });
      
      print('✅ Settings saved locally');
    } catch (e, stackTrace) {
      print('❌ Error saving settings: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  static Future<SettingsState> loadSettings({String? userEmail}) async {
    if (_settingsBox == null) {
      print('Storage not initialized. Returning default settings.');
      return SettingsState();
    }

    try {
      final key = _getUserKey(userEmail ?? _currentUserEmail, 'settings');
      final settingsData = _settingsBox!.get(key) as Map<String, dynamic>?;
      
      if (settingsData == null) {
        print('No settings found locally');
        return SettingsState();
      }

      final currencyName = settingsData['currency'] as String?;
      final namingFormatName = settingsData['namingFormat'] as String?;
      final themeModeName = settingsData['themeMode'] as String?;

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

      final widgetSettingsData = settingsData['widgetSettings'];
      final widgetSettings = widgetSettingsData != null
          ? WidgetSettings.fromJson(Map<String, dynamic>.from(widgetSettingsData))
          : WidgetSettings();

      print('Settings loaded from local storage');
      return SettingsState(
        currency: currency,
        namingFormat: namingFormat,
        themeMode: themeMode,
        widgetSettings: widgetSettings,
      );
    } catch (e) {
      print('Error loading settings: $e');
      return SettingsState();
    }
  }

  static Future<void> saveFinancialProfile(FinancialProfile profile, {String? userEmail}) async {
    if (_financialProfileBox == null) {
      throw Exception('Storage not initialized');
    }

    try {
      final key = _getUserKey(userEmail ?? _currentUserEmail, 'financialProfile');
      await _financialProfileBox!.put(key, profile.toJson());
      
      print('✅ Financial profile saved locally');
    } catch (e, stackTrace) {
      print('❌ Error saving financial profile: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  static Future<FinancialProfile> loadFinancialProfile({String? userEmail}) async {
    if (_financialProfileBox == null) {
      print('Storage not initialized. Returning default profile.');
      return FinancialProfile();
    }

    try {
      final key = _getUserKey(userEmail ?? _currentUserEmail, 'financialProfile');
      final profileData = _financialProfileBox!.get(key) as Map<String, dynamic>?;

      if (profileData == null) {
        print('No financial profile found locally');
        return FinancialProfile();
      }

      print('Financial profile loaded from local storage');
      return FinancialProfile.fromJson(profileData);
    } catch (e) {
      print('Error loading financial profile: $e');
      return FinancialProfile();
    }
  }

  static Future<void> saveAuthState(String email, String name, String? pictureUrl) async {
    if (_authBox == null) {
      throw Exception('Storage not initialized');
    }

    try {
      _setCurrentUser(email);
      await _authBox!.put('user', {
        'email': email,
        'name': name,
        'pictureUrl': pictureUrl,
      });
      print('✅ Auth state saved locally');
    } catch (e) {
      print('❌ Error saving auth state: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> loadAuthState() async {
    if (_authBox == null) {
      return null;
    }

    try {
      final userData = _authBox!.get('user') as Map<String, dynamic>?;
      if (userData != null) {
        _setCurrentUser(userData['email'] as String);
      }
      return userData;
    } catch (e) {
      print('Error loading auth state: $e');
      return null;
    }
  }

  static Future<void> clearAuthState() async {
    if (_authBox == null) {
      return;
    }

    try {
      await _authBox!.delete('user');
      _currentUserEmail = null;
      print('✅ Auth state cleared');
    } catch (e) {
      print('❌ Error clearing auth state: $e');
    }
  }

  static Future<void> clearAll({String? userEmail}) async {
    final email = userEmail ?? _currentUserEmail;
    if (email == null) {
      return;
    }

    try {
      // Clear all data for the current user
      if (_receiptsBox != null) {
        await _receiptsBox!.delete(_getUserKey(email, 'receipts'));
      }
      if (_settingsBox != null) {
        await _settingsBox!.delete(_getUserKey(email, 'settings'));
      }
      if (_financialProfileBox != null) {
        await _financialProfileBox!.delete(_getUserKey(email, 'financialProfile'));
      }
      
      print('All user data cleared from local storage');
    } catch (e) {
      print('Error clearing user data: $e');
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
}

