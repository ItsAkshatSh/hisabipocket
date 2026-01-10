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
    // Firebase handles user isolation automatically via Firebase Auth
    // This method is kept for compatibility but doesn't need to do anything
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
    // Auth state is now managed by Firebase Auth, but we keep this for compatibility
    // The actual auth state comes from Firebase Auth.currentUser
    print('Auth state saved (Firebase Auth handles this automatically)');
  }

  static Future<Map<String, dynamic>?> loadAuthState() async {
    // Auth state is now managed by Firebase Auth
    // Return null to indicate no saved auth state (Firebase Auth will handle it)
    return null;
  }

  static Future<void> clearAuthState() async {
    // Clear Firebase data
    await firebase.FirebaseStorageService.clearAll();
    print('Auth state and user data cleared');
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

