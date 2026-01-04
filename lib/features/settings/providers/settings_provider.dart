import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisabi/core/storage/storage_service.dart';

enum Currency { 
  USD, EUR, GBP, JPY, CNY, INR, AUD, CAD, 
  AED, SAR, ZAR, BRL, MXN, KRW, SGD, HKD, 
  CHF, SEK, NOK, DKK, PLN, TRY, RUB, NZD 
}

enum NamingFormat { storeDate, dateStore, storeOnly, dateOnly }
enum AppThemeMode { light, dark, system }

class SettingsState {
  final Currency currency;
  final NamingFormat namingFormat;
  final AppThemeMode themeMode;
  
  SettingsState({
    this.currency = Currency.USD, 
    this.namingFormat = NamingFormat.storeDate,
    this.themeMode = AppThemeMode.dark,
  });

  SettingsState copyWith({
    Currency? currency,
    NamingFormat? namingFormat,
    AppThemeMode? themeMode,
  }) {
    return SettingsState(
      currency: currency ?? this.currency,
      namingFormat: namingFormat ?? this.namingFormat,
      themeMode: themeMode ?? this.themeMode,
    );
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, AsyncValue<SettingsState>>((ref) {
  return SettingsNotifier()..loadSettings();
});

class SettingsNotifier extends StateNotifier<AsyncValue<SettingsState>> {
  SettingsNotifier() : super(const AsyncValue.loading());

  Future<void> loadSettings() async {
    state = const AsyncValue.loading();
    try {
      final settings = await StorageService.loadSettings();
      state = AsyncValue.data(settings);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> setCurrency(Currency newCurrency) async {
    final currentSettings = state.valueOrNull ?? SettingsState();
    final updatedSettings = currentSettings.copyWith(currency: newCurrency);
    state = AsyncValue.data(updatedSettings);
    
    try {
      await StorageService.saveSettings(updatedSettings);
    } catch (e) {
      await loadSettings();
      rethrow;
    }
  }

  Future<void> setNamingFormat(NamingFormat newFormat) async {
    final currentSettings = state.valueOrNull ?? SettingsState();
    final updatedSettings = currentSettings.copyWith(namingFormat: newFormat);
    state = AsyncValue.data(updatedSettings);
    
    try {
      await StorageService.saveSettings(updatedSettings);
    } catch (e) {
      await loadSettings();
      rethrow;
    }
  }

  Future<void> setThemeMode(AppThemeMode newThemeMode) async {
    final currentSettings = state.valueOrNull ?? SettingsState();
    final updatedSettings = currentSettings.copyWith(themeMode: newThemeMode);
    state = AsyncValue.data(updatedSettings);
    
    try {
      await StorageService.saveSettings(updatedSettings);
    } catch (e) {
      await loadSettings();
      rethrow;
    }
  }
}
