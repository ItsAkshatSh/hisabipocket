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
      keywords: ['rent', 'utility', 'electric', 'water', 'gas', 'insurance', 'maintenance', 'mortgage'],
    ),
    ExpenseCategory.food: CategoryInfo(
      category: ExpenseCategory.food,
      name: 'Food & Dining',
      emoji: '🍽️',
      color: Color(0xFF4CAF50),
      keywords: ['grocery', 'food', 'restaurant', 'cafe', 'coffee', 'shawarma', 'kebab', 'pizza', 'burger', 'lunch', 'dinner', 'breakfast', 'bakery', 'talabat', 'zomato', 'deliveroo', 'eats'],
    ),
    ExpenseCategory.transport: CategoryInfo(
      category: ExpenseCategory.transport,
      name: 'Transport',
      emoji: '🚗',
      color: Color(0xFF2196F3),
      keywords: ['fuel', 'gas', 'uber', 'lyft', 'taxi', 'parking', 'metro', 'bus', 'train', 'airline', 'flight', 'petrol'],
    ),
    ExpenseCategory.health: CategoryInfo(
      category: ExpenseCategory.health,
      name: 'Health',
      emoji: '🏥',
      color: Color(0xFFE91E63),
      keywords: ['pharmacy', 'medicine', 'doctor', 'hospital', 'clinic', 'medical', 'dental', 'vision'],
    ),
    ExpenseCategory.lifestyle: CategoryInfo(
      category: ExpenseCategory.lifestyle,
      name: 'Lifestyle',
      emoji: '🛍️',
      color: Color(0xFF00BCD4),
      keywords: ['amazon', 'shopping', 'clothes', 'fashion', 'salon', 'barber', 'spa', 'beauty', 'gift', 'electronics', 'hardware'],
    ),
    ExpenseCategory.subscriptions: CategoryInfo(
      category: ExpenseCategory.subscriptions,
      name: 'Subscriptions & Fun',
      emoji: '🎬',
      color: Color(0xFF673AB7),
      keywords: ['subscription', 'membership', 'netflix', 'spotify', 'gym', 'movie', 'cinema', 'game', 'entertainment'],
    ),
    ExpenseCategory.education: CategoryInfo(
      category: ExpenseCategory.education,
      name: 'Education',
      emoji: '📚',
      color: Color(0xFF3F51B5),
      keywords: ['school', 'tuition', 'course', 'book', 'university', 'college', 'learning'],
    ),
    ExpenseCategory.travel: CategoryInfo(
      category: ExpenseCategory.travel,
      name: 'Travel',
      emoji: '✈️',
      color: Color(0xFF009688),
      keywords: ['hotel', 'vacation', 'trip', 'airbnb', 'resort', 'flight', 'booking'],
    ),
    ExpenseCategory.other: CategoryInfo(
      category: ExpenseCategory.other,
      name: 'Other',
      emoji: '📦',
      color: Color(0xFF9E9E9E),
      keywords: [],
    ),
  };

  // Efficient flat lookup map
  static final Map<String, ExpenseCategory> _lookupMap = _generateLookupMap();

  static Map<String, ExpenseCategory> _generateLookupMap() {
    final map = <String, ExpenseCategory>{};
    // Map enum names
    for (final cat in ExpenseCategory.values) {
      map[cat.name] = cat;
    }
    // Map keywords
    for (final entry in categories.entries) {
      for (final keyword in entry.value.keywords) {
        map[keyword] = entry.key;
      }
    }
    // Map common multi-word variations
    map['food & dining'] = ExpenseCategory.food;
    map['housing & bills'] = ExpenseCategory.housing;
    map['subscriptions & fun'] = ExpenseCategory.subscriptions;
    return map;
  }

  static CategoryInfo getInfo(ExpenseCategory category) {
    return categories[category] ?? categories[ExpenseCategory.other]!;
  }

  /// Maps any string to the current ExpenseCategory enum using an efficient token lookup
  static ExpenseCategory mapStringToCategory(String? input) {
    if (input == null || input.isEmpty) return ExpenseCategory.other;
    
    final normalized = input.toLowerCase().trim();
    
    // Direct lookup for exact matches or common phrases
    if (_lookupMap.containsKey(normalized)) return _lookupMap[normalized]!;

    // Token-based lookup: check each word in the input
    final tokens = normalized.split(RegExp(r'[^a-z0-9&]')).where((t) => t.isNotEmpty);
    for (final token in tokens) {
      if (_lookupMap.containsKey(token)) return _lookupMap[token]!;
    }

    return ExpenseCategory.other;
  }
}
