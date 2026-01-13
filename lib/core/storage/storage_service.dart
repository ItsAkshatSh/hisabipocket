import 'package:hisabi/core/models/receipt_model.dart';
import 'package:hisabi/features/settings/providers/settings_provider.dart';
import 'package:hisabi/features/financial_profile/models/financial_profile_model.dart';
import 'package:hisabi/core/storage/local_storage_service.dart';

class StorageService {
  static Future<void> init() async {
    await LocalStorageService.init();
    print('Storage initialized successfully');
  }
  
  static Future<void> initializeUserStorage(String userEmail) async {
    print('User storage initialized for: $userEmail');
  }

  static Future<void> saveReceipts(List<ReceiptModel> receipts) async {
    await LocalStorageService.saveReceipts(receipts);
  }

  static Future<List<ReceiptModel>> loadReceipts() async {
    return await LocalStorageService.loadReceipts();
  }

  static Future<void> addReceipt(ReceiptModel receipt) async {
    await LocalStorageService.addReceipt(receipt);
  }

  static Future<void> deleteReceipt(String receiptId) async {
    await LocalStorageService.deleteReceipt(receiptId);
  }

  static Future<void> saveSettings(SettingsState settings) async {
    await LocalStorageService.saveSettings(settings);
  }

  static Future<SettingsState> loadSettings() async {
    return await LocalStorageService.loadSettings();
  }

  static Future<void> saveAuthState(String email, String name, String? pictureUrl) async {
    await LocalStorageService.saveAuthState(email, name, pictureUrl);
  }

  static Future<Map<String, dynamic>?> loadAuthState() async {
    return await LocalStorageService.loadAuthState();
  }

  static Future<void> clearAuthState() async {
    await LocalStorageService.clearAuthState();
  }

  static Future<void> saveFinancialProfile(FinancialProfile profile) async {
    await LocalStorageService.saveFinancialProfile(profile);
  }

  static Future<FinancialProfile> loadFinancialProfile() async {
    return await LocalStorageService.loadFinancialProfile();
  }

  static Future<void> clearAll() async {
    await LocalStorageService.clearAll();
    print('All data cleared');
  }
}

