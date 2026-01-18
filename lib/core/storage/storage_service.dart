import 'package:hisabi/core/models/receipt_model.dart';
import 'package:hisabi/core/storage/firebase_storage_service.dart' as firebase;
import 'package:hisabi/features/settings/providers/settings_provider.dart';
import 'package:hisabi/features/financial_profile/models/financial_profile_model.dart';

class StorageService {
  static Future<void> init() async {
    await firebase.FirebaseStorageService.init();
  }

  static Future<void> initializeUserStorage() async {
    // Firebase handles user isolation automatically
    print('Firebase handles user data isolation automatically');
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

  static Future<void> saveFinancialProfile(FinancialProfile profile) async {
    await firebase.FirebaseStorageService.saveFinancialProfile(profile);
  }

  static Future<FinancialProfile> loadFinancialProfile() async {
    return await firebase.FirebaseStorageService.loadFinancialProfile();
  }

  static Future<void> saveAuthState(String email) async {
    // Firebase Auth handles auth state
    print('Firebase Auth handles authentication state');
  }

  static String? loadAuthState() {
    // Firebase Auth manages auth state
    return null;
  }

  static Future<void> clearAuthState() async {
    // Don't clear user data on logout, just sign out
    // Firebase Auth handles sign out separately
    print('Firebase Auth handles sign out');
  }
}
