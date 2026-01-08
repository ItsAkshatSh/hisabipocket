import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:hisabi/core/storage/storage_service.dart';

enum Currency { 
  USD, EUR, GBP, JPY, CNY, INR, AUD, CAD, 
  AED, SAR, ZAR, BRL, MXN, KRW, SGD, HKD, 
  CHF, SEK, NOK, DKK, PLN, TRY, RUB, NZD 
}

enum NamingFormat { storeDate, dateStore, storeOnly, dateOnly }
enum AppThemeMode { light, dark, system }

enum WidgetStat {
  totalThisMonth,
  topStore,
  receiptsCount,
  averagePerReceipt,
  daysWithExpenses,
  totalItems,
}

class WidgetSettings {
  final Set<WidgetStat> enabledStats;
  
  WidgetSettings({
    Set<WidgetStat>? enabledStats,
  }) : enabledStats = enabledStats ?? {
          WidgetStat.totalThisMonth,
          WidgetStat.topStore,
        };

  WidgetSettings copyWith({
    Set<WidgetStat>? enabledStats,
  }) {
    return WidgetSettings(
      enabledStats: enabledStats ?? this.enabledStats,
    );
  }

  Map<String, dynamic> toJson() => {
        'enabledStats': enabledStats.map((e) => e.name).toList(),
      };

  factory WidgetSettings.fromJson(Map<String, dynamic> json) {
    final statsList = (json['enabledStats'] as List<dynamic>?)
            ?.map((e) => WidgetStat.values.firstWhere(
                  (stat) => stat.name == e,
                  orElse: () => WidgetStat.totalThisMonth,
                ))
            .toSet() ??
        {WidgetStat.totalThisMonth, WidgetStat.topStore};
    return WidgetSettings(enabledStats: statsList);
  }
}

class SettingsState {
  final Currency currency;
  final NamingFormat namingFormat;
  final AppThemeMode themeMode;
  final WidgetSettings widgetSettings;
  
  SettingsState({
    this.currency = Currency.USD, 
    this.namingFormat = NamingFormat.storeDate,
    this.themeMode = AppThemeMode.dark,
    WidgetSettings? widgetSettings,
  }) : widgetSettings = widgetSettings ?? WidgetSettings();

  SettingsState copyWith({
    Currency? currency,
    NamingFormat? namingFormat,
    AppThemeMode? themeMode,
    WidgetSettings? widgetSettings,
  }) {
    return SettingsState(
      currency: currency ?? this.currency,
      namingFormat: namingFormat ?? this.namingFormat,
      themeMode: themeMode ?? this.themeMode,
      widgetSettings: widgetSettings ?? this.widgetSettings,
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
      // Update widget with new currency
      await _saveWidgetSettingsToHomeWidget(
        currentSettings.widgetSettings,
        newCurrency,
      );
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

  Future<void> setWidgetSettings(WidgetSettings newWidgetSettings) async {
    final currentSettings = state.valueOrNull ?? SettingsState();
    final updatedSettings = currentSettings.copyWith(widgetSettings: newWidgetSettings);
    state = AsyncValue.data(updatedSettings);
    
    try {
      await StorageService.saveSettings(updatedSettings);
      // Also save to HomeWidget for immediate widget update
      await _saveWidgetSettingsToHomeWidget(newWidgetSettings, currentSettings.currency);
    } catch (e) {
      await loadSettings();
      rethrow;
    }
  }

  Future<void> _saveWidgetSettingsToHomeWidget(WidgetSettings widgetSettings, Currency currency) async {
    try {
      await HomeWidget.saveWidgetData<String>(
        'widget_settings',
        jsonEncode(widgetSettings.toJson()),
      );
      await HomeWidget.saveWidgetData<String>(
        'currency_code',
        currency.name,
      );
      await HomeWidget.updateWidget(name: 'HisabiWidgetProvider');
    } catch (e) {
      // Silently fail - widget will update on next receipt save
      print('Error saving widget settings to HomeWidget: $e');
    }
  }
}
