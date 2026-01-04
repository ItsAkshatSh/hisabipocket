import 'dart:convert';

import 'package:home_widget/home_widget.dart';

class WidgetSummary {
  final double totalThisMonth;
  final String topStore;
  final DateTime updatedAt;

  const WidgetSummary({
    required this.totalThisMonth,
    required this.topStore,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'totalThisMonth': totalThisMonth,
        'topStore': topStore,
        'updatedAt': updatedAt.toIso8601String(),
      };

  static WidgetSummary fromJson(Map<String, dynamic> json) {
    return WidgetSummary(
      totalThisMonth: (json['totalThisMonth'] as num?)?.toDouble() ?? 0,
      topStore: (json['topStore'] as String?) ?? '—',
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
}) async {
  await HomeWidget.saveWidgetData<String>(
    'widget_summary',
    jsonEncode(summary.toJson()),
  );

  await HomeWidget.updateWidget(
    name: androidProvider,
    iOSName: iosProvider,
  );
}










