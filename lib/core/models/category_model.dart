import 'package:flutter/material.dart';

enum ExpenseCategory {
  // Essential
  groceries,
  utilities,
  rent,
  transportation,
  healthcare,
  insurance,
  
  // Lifestyle
  dining,
  entertainment,
  shopping,
  clothing,
  personalCare,
  subscriptions,
  
  // Financial
  savings,
  investments,
  debt,
  education,
  gifts,
  charity,
  
  // Other
  travel,
  homeImprovement,
  petCare,
  business,
  other,
}

class CategoryInfo {
  final ExpenseCategory category;
  final String name;
  final String emoji;
  final Color color;
  final List<String> keywords;
  
  const CategoryInfo({
    required this.category,
    required this.name,
    required this.emoji,
    required this.color,
    required this.keywords,
  });
  
  static const Map<ExpenseCategory, CategoryInfo> categories = {
    ExpenseCategory.groceries: CategoryInfo(
      category: ExpenseCategory.groceries,
      name: 'Groceries',
      emoji: '🛒',
      color: Color(0xFF4CAF50),
      keywords: ['grocery', 'supermarket', 'food', 'walmart', 'target', 'kroger', 'safeway', 'whole foods', 'aldi', 'costco'],
    ),
    ExpenseCategory.dining: CategoryInfo(
      category: ExpenseCategory.dining,
      name: 'Dining',
      emoji: '🍽️',
      color: Color(0xFFFF9800),
      keywords: ['restaurant', 'cafe', 'food', 'dining', 'mcdonalds', 'starbucks', 'pizza', 'burger', 'coffee', 'lunch', 'dinner', 'breakfast'],
    ),
    ExpenseCategory.transportation: CategoryInfo(
      category: ExpenseCategory.transportation,
      name: 'Transportation',
      emoji: '🚗',
      color: Color(0xFF2196F3),
      keywords: ['gas', 'fuel', 'uber', 'lyft', 'taxi', 'parking', 'metro', 'bus', 'train', 'airline', 'flight'],
    ),
    ExpenseCategory.utilities: CategoryInfo(
      category: ExpenseCategory.utilities,
      name: 'Utilities',
      emoji: '💡',
      color: Color(0xFFFFC107),
      keywords: ['electric', 'water', 'gas', 'internet', 'phone', 'utility', 'power', 'cable', 'wifi'],
    ),
    ExpenseCategory.rent: CategoryInfo(
      category: ExpenseCategory.rent,
      name: 'Rent',
      emoji: '🏠',
      color: Color(0xFF9C27B0),
      keywords: ['rent', 'housing', 'apartment', 'mortgage'],
    ),
    ExpenseCategory.healthcare: CategoryInfo(
      category: ExpenseCategory.healthcare,
      name: 'Healthcare',
      emoji: '🏥',
      color: Color(0xFFE91E63),
      keywords: ['pharmacy', 'drug', 'medicine', 'doctor', 'hospital', 'clinic', 'medical', 'health'],
    ),
    ExpenseCategory.insurance: CategoryInfo(
      category: ExpenseCategory.insurance,
      name: 'Insurance',
      emoji: '🛡️',
      color: Color(0xFF607D8B),
      keywords: ['insurance', 'premium', 'coverage'],
    ),
    ExpenseCategory.entertainment: CategoryInfo(
      category: ExpenseCategory.entertainment,
      name: 'Entertainment',
      emoji: '🎬',
      color: Color(0xFFE91E63),
      keywords: ['movie', 'cinema', 'netflix', 'spotify', 'game', 'concert', 'theater', 'ticket'],
    ),
    ExpenseCategory.shopping: CategoryInfo(
      category: ExpenseCategory.shopping,
      name: 'Shopping',
      emoji: '🛍️',
      color: Color(0xFF00BCD4),
      keywords: ['amazon', 'store', 'mall', 'purchase', 'buy'],
    ),
    ExpenseCategory.clothing: CategoryInfo(
      category: ExpenseCategory.clothing,
      name: 'Clothing',
      emoji: '👕',
      color: Color(0xFF795548),
      keywords: ['clothes', 'shirt', 'pants', 'shoes', 'fashion', 'apparel'],
    ),
    ExpenseCategory.personalCare: CategoryInfo(
      category: ExpenseCategory.personalCare,
      name: 'Personal Care',
      emoji: '💅',
      color: Color(0xFFFF6B9D),
      keywords: ['salon', 'barber', 'spa', 'beauty', 'cosmetic', 'gym', 'fitness'],
    ),
    ExpenseCategory.subscriptions: CategoryInfo(
      category: ExpenseCategory.subscriptions,
      name: 'Subscriptions',
      emoji: '📱',
      color: Color(0xFF673AB7),
      keywords: ['subscription', 'membership', 'premium', 'plan'],
    ),
    ExpenseCategory.travel: CategoryInfo(
      category: ExpenseCategory.travel,
      name: 'Travel',
      emoji: '✈️',
      color: Color(0xFF009688),
      keywords: ['hotel', 'travel', 'vacation', 'trip', 'booking', 'airbnb'],
    ),
    ExpenseCategory.education: CategoryInfo(
      category: ExpenseCategory.education,
      name: 'Education',
      emoji: '📚',
      color: Color(0xFF3F51B5),
      keywords: ['school', 'tuition', 'course', 'book', 'education', 'learning'],
    ),
    ExpenseCategory.gifts: CategoryInfo(
      category: ExpenseCategory.gifts,
      name: 'Gifts',
      emoji: '🎁',
      color: Color(0xFFFF5722),
      keywords: ['gift', 'present', 'donation'],
    ),
    ExpenseCategory.other: CategoryInfo(
      category: ExpenseCategory.other,
      name: 'Other',
      emoji: '📦',
      color: Color(0xFF9E9E9E),
      keywords: [],
    ),
  };
  
  static CategoryInfo getInfo(ExpenseCategory category) {
    return categories[category] ?? categories[ExpenseCategory.other]!;
  }
}

