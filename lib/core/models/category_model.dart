import 'package:flutter/material.dart';

enum ExpenseCategory {
  housing,        // Rent, Utilities, Insurance
  food,           // Groceries, Dining
  transport,      // Commute, Fuel, Uber
  health,         // Medical, Pharmacy
  lifestyle,      // Shopping, Clothes, Grooming, Gifts
  subscriptions,  // Entertainment, Netflix, Gym, Memberships
  education,      // Learning, Books
  travel,         // Trips, Hotels
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
    ExpenseCategory.housing: CategoryInfo(
      category: ExpenseCategory.housing,
      name: 'Housing & Bills',
      emoji: '🏠',
      color: Color(0xFF9C27B0),
      keywords: ['rent', 'housing', 'apartment', 'mortgage', 'electric', 'water', 'gas', 'utility', 'power', 'insurance', 'premium', 'coverage', 'bill', 'home'],
    ),
    ExpenseCategory.food: CategoryInfo(
      category: ExpenseCategory.food,
      name: 'Food & Dining',
      emoji: '🍽️',
      color: Color(0xFF4CAF50),
      keywords: ['grocery', 'supermarket', 'food', 'walmart', 'target', 'kroger', 'safeway', 'whole foods', 'aldi', 'costco', 'restaurant', 'cafe', 'mcdonalds', 'starbucks', 'pizza', 'burger', 'coffee', 'lunch', 'dinner', 'breakfast', 'bakery', 'apple', 'banana', 'orange', 'fruit', 'vegetable', 'produce'],
    ),
    ExpenseCategory.transport: CategoryInfo(
      category: ExpenseCategory.transport,
      name: 'Transport',
      emoji: '🚗',
      color: Color(0xFF2196F3),
      keywords: ['gas', 'fuel', 'uber', 'lyft', 'taxi', 'parking', 'metro', 'bus', 'train', 'airline', 'flight', 'commute', 'petrol'],
    ),
    ExpenseCategory.health: CategoryInfo(
      category: ExpenseCategory.health,
      name: 'Health',
      emoji: '🏥',
      color: Color(0xFFE91E63),
      keywords: ['pharmacy', 'drug', 'medicine', 'doctor', 'hospital', 'clinic', 'medical', 'health', 'dentist', 'vision'],
    ),
    ExpenseCategory.lifestyle: CategoryInfo(
      category: ExpenseCategory.lifestyle,
      name: 'Lifestyle',
      emoji: '🛍️',
      color: Color(0xFF00BCD4),
      keywords: ['amazon', 'store', 'mall', 'purchase', 'buy', 'clothes', 'shirt', 'pants', 'shoes', 'fashion', 'apparel', 'salon', 'barber', 'spa', 'beauty', 'cosmetic', 'gift', 'present', 'shopping', 'electronics', 'phone', 'laptop', 'computer', 'device', 'hardware'],
    ),
    ExpenseCategory.subscriptions: CategoryInfo(
      category: ExpenseCategory.subscriptions,
      name: 'Subscriptions & Fun',
      emoji: '🎬',
      color: Color(0xFF673AB7),
      keywords: ['subscription', 'membership', 'premium', 'plan', 'movie', 'cinema', 'netflix', 'spotify', 'game', 'concert', 'theater', 'ticket', 'gym', 'fitness', 'apple music', 'apple tv', 'app store', 'itunes', 'google play', 'entertainment'],
    ),
    ExpenseCategory.education: CategoryInfo(
      category: ExpenseCategory.education,
      name: 'Education',
      emoji: '📚',
      color: Color(0xFF3F51B5),
      keywords: ['school', 'tuition', 'course', 'book', 'education', 'learning', 'university', 'college'],
    ),
    ExpenseCategory.travel: CategoryInfo(
      category: ExpenseCategory.travel,
      name: 'Travel',
      emoji: '✈️',
      color: Color(0xFF009688),
      keywords: ['hotel', 'travel', 'vacation', 'trip', 'booking', 'airbnb', 'flight', 'resort'],
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

  /// Maps an old category string or any string to the current ExpenseCategory enum
  static ExpenseCategory mapStringToCategory(String? name) {
    if (name == null || name.isEmpty) return ExpenseCategory.other;
    
    final normalized = name.toLowerCase().trim();
    
    // Exact enum name match
    for (final value in ExpenseCategory.values) {
      if (value.name == normalized) return value;
    }

    // Legacy/Old Category Mapping
    final mapping = {
      'groceries': ExpenseCategory.food,
      'dining': ExpenseCategory.food,
      'restaurants': ExpenseCategory.food,
      'utilities': ExpenseCategory.housing,
      'rent': ExpenseCategory.housing,
      'insurance': ExpenseCategory.housing,
      'housing': ExpenseCategory.housing,
      'transportation': ExpenseCategory.transport,
      'healthcare': ExpenseCategory.health,
      'medical': ExpenseCategory.health,
      'shopping': ExpenseCategory.lifestyle,
      'clothing': ExpenseCategory.lifestyle,
      'personalcare': ExpenseCategory.lifestyle,
      'gifts': ExpenseCategory.lifestyle,
      'entertainment': ExpenseCategory.subscriptions,
      'subscriptions': ExpenseCategory.subscriptions,
      'travel': ExpenseCategory.travel,
      'education': ExpenseCategory.education,
    };

    if (mapping.containsKey(normalized)) {
      return mapping[normalized]!;
    }

    // Keyword based search as a fallback
    for (final entry in categories.entries) {
      if (entry.value.keywords.any((k) => normalized.contains(k))) {
        return entry.key;
      }
    }

    return ExpenseCategory.other;
  }
}
