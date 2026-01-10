import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hisabi/core/models/receipt_model.dart';
import 'package:hisabi/core/models/category_model.dart';
import 'package:hisabi/features/settings/providers/settings_provider.dart';
import 'package:hisabi/features/financial_profile/models/financial_profile_model.dart';

class FirebaseStorageService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static String? get currentUserId => _auth.currentUser?.uid;
  static String? get currentUserEmail => _auth.currentUser?.email;

  static Future<void> init() async {
    try {
      // Enable Firestore offline persistence
      _firestore.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
      print('✅ Firebase storage initialized with offline persistence');
    } catch (e) {
      print('⚠️ Warning: Could not enable Firestore offline persistence: $e');
      print('Firebase storage initialized (without offline persistence)');
    }
  }

  static Future<void> saveReceipts(List<ReceiptModel> receipts) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      final receiptsJson = receipts.map((r) => _receiptToJson(r)).toList();
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('receipts')
          .doc('list')
          .set({'receipts': receiptsJson});
      
      print('✅ Saved ${receipts.length} receipts to Firebase for user: $userId');
    } catch (e, stackTrace) {
      print('❌ Error saving receipts to Firebase: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  static Future<List<ReceiptModel>> loadReceipts() async {
    final userId = currentUserId;
    if (userId == null) {
      print('User not authenticated. Returning empty receipts.');
      return [];
    }

    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('receipts')
          .doc('list')
          .get();

      if (!doc.exists || doc.data() == null) {
        print('No receipts found in Firebase');
        return [];
      }

      final data = doc.data()!;
      final receiptsData = data['receipts'] as List?;
      
      if (receiptsData == null) {
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

      print('Successfully loaded ${loadedReceipts.length} receipts from Firebase');
      return loadedReceipts;
    } catch (e) {
      print('Error loading receipts from Firebase: $e');
      return [];
    }
  }

  static Future<void> addReceipt(ReceiptModel receipt) async {
    final receipts = await loadReceipts();
    receipts.add(receipt);
    await saveReceipts(receipts);
  }

  static Future<void> deleteReceipt(String receiptId) async {
    final receipts = await loadReceipts();
    receipts.removeWhere((r) => r.id == receiptId);
    await saveReceipts(receipts);
  }

  static Future<void> saveSettings(SettingsState settings) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .set({
            'settings': {
              'currency': settings.currency.name,
              'namingFormat': settings.namingFormat.name,
              'themeMode': settings.themeMode.name,
              'widgetSettings': settings.widgetSettings.toJson(),
            }
          }, SetOptions(merge: true));
      
      print('✅ Settings saved to Firebase for user: $userId');
    } catch (e, stackTrace) {
      print('❌ Error saving settings to Firebase: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  static Future<SettingsState> loadSettings() async {
    final userId = currentUserId;
    if (userId == null) {
      print('User not authenticated. Returning default settings.');
      return SettingsState();
    }

    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (!doc.exists || doc.data() == null) {
        print('No settings found in Firebase');
        return SettingsState();
      }

      final data = doc.data()!;
      final settingsData = data['settings'] as Map<String, dynamic>?;
      
      if (settingsData == null) {
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

      print('Settings loaded from Firebase for user: $userId');
      return SettingsState(
        currency: currency,
        namingFormat: namingFormat,
        themeMode: themeMode,
        widgetSettings: widgetSettings,
      );
    } catch (e) {
      print('Error loading settings from Firebase: $e');
      return SettingsState();
    }
  }

  static Future<void> saveFinancialProfile(FinancialProfile profile) async {
    final userId = currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .set({
            'financialProfile': profile.toJson(),
          }, SetOptions(merge: true));
      
      print('✅ Financial profile saved to Firebase for user: $userId');
    } catch (e, stackTrace) {
      print('❌ Error saving financial profile to Firebase: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  static Future<FinancialProfile> loadFinancialProfile() async {
    final userId = currentUserId;
    if (userId == null) {
      print('User not authenticated. Returning default profile.');
      return FinancialProfile();
    }

    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .get();

      if (!doc.exists || doc.data() == null) {
        print('No financial profile found in Firebase');
        return FinancialProfile();
      }

      final data = doc.data()!;
      final profileData = data['financialProfile'] as Map<String, dynamic>?;

      if (profileData == null) {
        return FinancialProfile();
      }

      print('Financial profile loaded from Firebase for user: $userId');
      return FinancialProfile.fromJson(profileData);
    } catch (e) {
      print('Error loading financial profile from Firebase: $e');
      return FinancialProfile();
    }
  }

  static Future<void> clearAll() async {
    final userId = currentUserId;
    if (userId == null) {
      return;
    }

    final batch = _firestore.batch();
    final userRef = _firestore.collection('users').doc(userId);
    
    batch.delete(userRef);
    
    final receiptsRef = userRef.collection('receipts');
    final receiptsSnapshot = await receiptsRef.get();
    for (var doc in receiptsSnapshot.docs) {
      batch.delete(doc.reference);
    }
    
    await batch.commit();
    print('All user data cleared from Firebase');
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

