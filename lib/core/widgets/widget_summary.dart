import 'dart:convert';

import 'package:home_widget/home_widget.dart';

class WidgetSummary {
  final double totalThisMonth;
  final String topStore;
  final int receiptsCount;
  final double averagePerReceipt;
  final int daysWithExpenses;
  final int totalItems;
  final DateTime updatedAt;

  const WidgetSummary({
    required this.totalThisMonth,
    required this.topStore,
    this.receiptsCount = 0,
    this.averagePerReceipt = 0.0,
    this.daysWithExpenses = 0,
    this.totalItems = 0,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'totalThisMonth': totalThisMonth,
        'topStore': topStore,
        'receiptsCount': receiptsCount,
        'averagePerReceipt': averagePerReceipt,
        'daysWithExpenses': daysWithExpenses,
        'totalItems': totalItems,
        'updatedAt': updatedAt.toIso8601String(),
      };

  static WidgetSummary fromJson(Map<String, dynamic> json) {
    return WidgetSummary(
      totalThisMonth: (json['totalThisMonth'] as num?)?.toDouble() ?? 0,
      topStore: (json['topStore'] as String?) ?? '—',
      receiptsCount: (json['receiptsCount'] as num?)?.toInt() ?? 0,
      averagePerReceipt: (json['averagePerReceipt'] as num?)?.toDouble() ?? 0.0,
      daysWithExpenses: (json['daysWithExpenses'] as num?)?.toInt() ?? 0,
      totalItems: (json['totalItems'] as num?)?.toInt() ?? 0,
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

/// Save summary data for the home widget and trigger a widget refresh.
Future<void> saveAndUpdateWidgetSummary(
  WidgetSummary summary, {
  String androidProvider = 'HisabiWidgetProvider',
  String? iosProvider,
  String? currencyCode,
  Map<String, dynamic>? widgetSettings,
}) async {
  await HomeWidget.saveWidgetData<String>(
    'widget_summary',
    jsonEncode(summary.toJson()),
  );
  
  if (currencyCode != null) {
    await HomeWidget.saveWidgetData<String>('currency_code', currencyCode);
  }
  
  if (widgetSettings != null) {
    await HomeWidget.saveWidgetData<String>(
      'widget_settings',
      jsonEncode(widgetSettings),
    );
  }

  await HomeWidget.updateWidget(
    name: androidProvider,
    iOSName: iosProvider,
  );
}














