
class DashboardStats {
  final double totalSpent;
  final int receiptsCount;
  final double averagePerReceipt;
  final String topStore;
  final double vsLastPeriodChange;
  final String trend; // 'up', 'down', 'flat'

  DashboardStats({
    required this.totalSpent,
    required this.receiptsCount,
    required this.averagePerReceipt,
    required this.topStore,
    required this.vsLastPeriodChange,
    required this.trend,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalSpent: json['total_spent']?.toDouble() ?? 0.0,
      receiptsCount: json['receipts_count'] ?? 0,
      averagePerReceipt: json['average_per_receipt']?.toDouble() ?? 0.0,
      topStore: json['top_store'] ?? 'N/A',
      vsLastPeriodChange: json['vs_last_period']['change']?.toDouble() ?? 0.0,
      trend: json['vs_last_period']['trend'] ?? 'flat',
    );
  }
}

class QuickStats {
  final double highestExpense;
  final double lowestExpense;
  final int daysWithExpenses;
  final int totalItems;

  QuickStats({
    required this.highestExpense,
    required this.lowestExpense,
    required this.daysWithExpenses,
    required this.totalItems,
  });

  factory QuickStats.fromJson(Map<String, dynamic> json) {
    return QuickStats(
      highestExpense: json['highest_expense']?.toDouble() ?? 0.0,
      lowestExpense: json['lowest_expense']?.toDouble() ?? 0.0,
      daysWithExpenses: json['days_with_expenses'] ?? 0,
      totalItems: json['total_items'] ?? 0,
    );
  }
}
