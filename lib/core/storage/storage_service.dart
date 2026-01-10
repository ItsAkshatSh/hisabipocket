import 'package:hisabi/core/models/receipt_model.dart';
import 'package:hisabi/features/settings/providers/settings_provider.dart';
import 'package:hisabi/features/financial_profile/models/financial_profile_model.dart';
import 'package:hisabi/core/storage/firebase_storage_service.dart' as firebase;

class StorageService {
  static Future<void> init() async {
    await firebase.FirebaseStorageService.init();
    print('Storage initialized successfully');
  }
  
  static Future<void> initializeUserStorage(String userEmail) async {
    print('User storage initialized for: $userEmail (Firebase handles isolation automatically)');
  }

  static Future<void> saveReceipts(List<ReceiptModel> receipts) async {
    await firebase.FirebaseStorageService.saveReceipts(receipts);
  }

  static Future<List<ReceiptModel>> loadReceipts() async {
    return await firebase.FirebaseStorageService.loadReceipts();
  }

  static Future<void> addReceipt(ReceiptModel receipt) async {
    await firebase.FirebaseStorageService.addReceipt(receipt);
  }

  static Future<void> deleteReceipt(String receiptId) async {
    await firebase.FirebaseStorageService.deleteReceipt(receiptId);
  }

  static Future<void> saveSettings(SettingsState settings) async {
    await firebase.FirebaseStorageService.saveSettings(settings);
  }

  static Future<SettingsState> loadSettings() async {
    return await firebase.FirebaseStorageService.loadSettings();
  }

  static Future<void> saveAuthState(String email, String name, String? pictureUrl) async {
    print('Auth state saved (Firebase Auth handles this automatically)');
  }

  static Future<Map<String, dynamic>?> loadAuthState() async {
    return null;
  }

  static Future<void> clearAuthState() async {
    print('Auth state cleared (user data preserved in Firebase)');
  }

  static Future<void> saveFinancialProfile(FinancialProfile profile) async {
    await firebase.FirebaseStorageService.saveFinancialProfile(profile);
  }

  static Future<FinancialProfile> loadFinancialProfile() async {
    return await firebase.FirebaseStorageService.loadFinancialProfile();
  }

  static Future<void> clearAll() async {
    await firebase.FirebaseStorageService.clearAll();
    print('All data cleared');
  }
}

