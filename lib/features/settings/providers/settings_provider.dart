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

enum AppThemeSelection {
  classic,
  midnight,
  forest,
  sunset,
  lavender,
  monochrome
}

enum WidgetStat {
  totalThisMonth,
  topStore,
  receiptsCount,
  averagePerReceipt,
  daysWithExpenses,
  totalItems,
  expenseTrend,
  savingsGoal,
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
  final AppThemeSelection themeSelection;
  final WidgetSettings widgetSettings;
  
  SettingsState({
    this.currency = Currency.USD, 
    this.namingFormat = NamingFormat.storeDate,
    this.themeMode = AppThemeMode.dark,
    this.themeSelection = AppThemeSelection.classic,
    WidgetSettings? widgetSettings,
  }) : widgetSettings = widgetSettings ?? WidgetSettings();

  SettingsState copyWith({
    Currency? currency,
    NamingFormat? namingFormat,
    AppThemeMode? themeMode,
    AppThemeSelection? themeSelection,
    WidgetSettings? widgetSettings,
  }) {
    return SettingsState(
      currency: currency ?? this.currency,
      namingFormat: namingFormat ?? this.namingFormat,
      themeMode: themeMode ?? this.themeMode,
      themeSelection: themeSelection ?? this.themeSelection,
      widgetSettings: widgetSettings ?? this.widgetSettings,
    );
  }

  Map<String, dynamic> toJson() => {
    'currency': currency.name,
    'namingFormat': namingFormat.name,
    'themeMode': themeMode.name,
    'themeSelection': themeSelection.name,
    'widgetSettings': widgetSettings.toJson(),
  };

  factory SettingsState.fromJson(Map<String, dynamic> json) {
    return SettingsState(
      currency: Currency.values.firstWhere((e) => e.name == json['currency'], orElse: () => Currency.USD),
      namingFormat: NamingFormat.values.firstWhere((e) => e.name == json['namingFormat'], orElse: () => NamingFormat.storeDate),
      themeMode: AppThemeMode.values.firstWhere((e) => e.name == json['themeMode'], orElse: () => AppThemeMode.dark),
      themeSelection: AppThemeSelection.values.firstWhere((e) => e.name == json['themeSelection'], orElse: () => AppThemeSelection.classic),
      widgetSettings: json['widgetSettings'] != null ? WidgetSettings.fromJson(Map<String, dynamic>.from(json['widgetSettings'])) : null,
    );
  }
}

final settingsProvider = StateNotifierProvider<SettingsNotifier, AsyncValue<SettingsState>>((ref) {
  final notifier = SettingsNotifier();
  notifier.loadSettings();
  return notifier;
});

class SettingsNotifier extends StateNotifier<AsyncValue<SettingsState>> {
  SettingsNotifier() : super(AsyncValue.data(SettingsState()));

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
    await _persistSettings(updatedSettings);
  }

  Future<void> setNamingFormat(NamingFormat newFormat) async {
    final currentSettings = state.valueOrNull ?? SettingsState();
    final updatedSettings = currentSettings.copyWith(namingFormat: newFormat);
    state = AsyncValue.data(updatedSettings);
    await _persistSettings(updatedSettings);
  }

  Future<void> setThemeMode(AppThemeMode newThemeMode) async {
    final currentSettings = state.valueOrNull ?? SettingsState();
    final updatedSettings = currentSettings.copyWith(themeMode: newThemeMode);
    state = AsyncValue.data(updatedSettings);
    await _persistSettings(updatedSettings);
  }

  Future<void> setThemeSelection(AppThemeSelection selection) async {
    final currentSettings = state.valueOrNull ?? SettingsState();
    final updatedSettings = currentSettings.copyWith(themeSelection: selection);
    state = AsyncValue.data(updatedSettings);
    await _persistSettings(updatedSettings);
  }

  Future<void> setWidgetSettings(WidgetSettings newWidgetSettings) async {
    final currentSettings = state.valueOrNull ?? SettingsState();
    final updatedSettings = currentSettings.copyWith(widgetSettings: newWidgetSettings);
    state = AsyncValue.data(updatedSettings);
    await _persistSettings(updatedSettings);
  }

  Future<void> _persistSettings(SettingsState settings) async {
    try {
      await StorageService.saveSettings(settings);
      await _saveWidgetSettingsToHomeWidget(settings.widgetSettings, settings.currency);
    } catch (e) {
      // Handle error
    }
  }

  Future<void> _saveWidgetSettingsToHomeWidget(WidgetSettings widgetSettings, Currency currency) async {
    try {
      await HomeWidget.saveWidgetData<String>('widget_settings', jsonEncode(widgetSettings.toJson()));
      await HomeWidget.saveWidgetData<String>('currency_code', currency.name);
      await HomeWidget.updateWidget(name: 'HisabiWidgetProvider');
    } catch (e) {}
  }
}
