import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisabi/core/storage/storage_service.dart';

enum Currency { AED, EUR, USD }
enum NamingFormat { storeDate, dateStore, storeOnly, dateOnly }

class SettingsState {
  final Currency currency;
  final NamingFormat namingFormat;
  
  SettingsState({this.currency = Currency.USD, this.namingFormat = NamingFormat.storeDate});

  SettingsState copyWith({
    Currency? currency,
    NamingFormat? namingFormat,
  }) {
    return SettingsState(
      currency: currency ?? this.currency,
      namingFormat: namingFormat ?? this.namingFormat,
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
}
