import 'package:hisabi/core/models/category_model.dart';

enum RuleMatchType {
  store,
  item,
  both,
}

class CategorizationRule {
  final String id;
  final String pattern;
  final RuleMatchType matchType;
  final ExpenseCategory category;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  CategorizationRule({
    required this.id,
    required this.pattern,
    required this.matchType,
    required this.category,
    this.isActive = true,
    DateTime? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool matches(String storeName, String itemName) {
    final lowerPattern = pattern.toLowerCase();
    switch (matchType) {
      case RuleMatchType.store:
        return storeName.toLowerCase().contains(lowerPattern);
      case RuleMatchType.item:
        return itemName.toLowerCase().contains(lowerPattern);
      case RuleMatchType.both:
        return storeName.toLowerCase().contains(lowerPattern) ||
            itemName.toLowerCase().contains(lowerPattern);
    }
  }

  CategorizationRule copyWith({
    String? id,
    String? pattern,
    RuleMatchType? matchType,
    ExpenseCategory? category,
    bool? isActive,
    DateTime? updatedAt,
  }) {
    return CategorizationRule(
      id: id ?? this.id,
      pattern: pattern ?? this.pattern,
      matchType: matchType ?? this.matchType,
      category: category ?? this.category,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'pattern': pattern,
        'matchType': matchType.name,
        'category': category.name,
        'isActive': isActive,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  factory CategorizationRule.fromJson(Map<String, dynamic> json) {
    return CategorizationRule(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      pattern: json['pattern'] as String? ?? '',
      matchType: RuleMatchType.values.firstWhere(
        (t) => t.name == json['matchType'],
        orElse: () => RuleMatchType.both,
      ),
      category: ExpenseCategory.values.firstWhere(
        (c) => c.name == json['category'],
        orElse: () => ExpenseCategory.other,
      ),
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
    );
  }
}

