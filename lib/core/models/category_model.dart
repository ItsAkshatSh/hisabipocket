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
  final IconData icon;
  final Color color;
  final List<String> keywords;
  
  const CategoryInfo({
    required this.category,
    required this.name,
    required this.emoji,
    required this.icon,
    required this.color,
    required this.keywords,
  });
  
  static const Map<ExpenseCategory, CategoryInfo> categories = {
    ExpenseCategory.housing: CategoryInfo(
      category: ExpenseCategory.housing,
      name: 'Housing & Bills',
      emoji: '🏠',
      icon: Icons.home_rounded,
      color: Color(0xFF9C27B0),
      keywords: ['rent', 'housing', 'apartment', 'mortgage', 'electric', 'water', 'gas', 'utility', 'power', 'insurance', 'premium', 'coverage', 'bill', 'home'],
    ),
    ExpenseCategory.food: CategoryInfo(
      category: ExpenseCategory.food,
      name: 'Food & Dining',
      emoji: '🍽️',
      icon: Icons.restaurant_rounded,
      color: Color(0xFF4CAF50),
      keywords: ['grocery', 'supermarket', 'food', 'walmart', 'target', 'kroger', 'safeway', 'whole foods', 'aldi', 'costco', 'restaurant', 'cafe', 'mcdonalds', 'starbucks', 'pizza', 'burger', 'coffee', 'lunch', 'dinner', 'breakfast', 'bakery', 'apple', 'banana', 'orange', 'fruit', 'vegetable', 'produce'],
    ),
    ExpenseCategory.transport: CategoryInfo(
      category: ExpenseCategory.transport,
      name: 'Transport',
      emoji: '🚗',
      icon: Icons.directions_car_rounded,
      color: Color(0xFF2196F3),
      keywords: ['gas', 'fuel', 'uber', 'lyft', 'taxi', 'parking', 'metro', 'bus', 'train', 'airline', 'flight', 'commute', 'petrol'],
    ),
    ExpenseCategory.health: CategoryInfo(
      category: ExpenseCategory.health,
      name: 'Health',
      emoji: '🏥',
      icon: Icons.local_hospital_rounded,
      color: Color(0xFFE91E63),
      keywords: ['pharmacy', 'drug', 'medicine', 'doctor', 'hospital', 'clinic', 'medical', 'health', 'dentist', 'vision'],
    ),
    ExpenseCategory.lifestyle: CategoryInfo(
      category: ExpenseCategory.lifestyle,
      name: 'Lifestyle',
      emoji: '🛍️',
      icon: Icons.shopping_bag_rounded,
      color: Color(0xFF00BCD4),
      keywords: ['amazon', 'store', 'mall', 'purchase', 'buy', 'clothes', 'shirt', 'pants', 'shoes', 'fashion', 'apparel', 'salon', 'barber', 'spa', 'beauty', 'cosmetic', 'gift', 'present', 'shopping', 'electronics', 'phone', 'laptop', 'computer', 'device', 'hardware'],
    ),
    ExpenseCategory.subscriptions: CategoryInfo(
      category: ExpenseCategory.subscriptions,
      name: 'Subscriptions & Fun',
      emoji: '🎬',
      icon: Icons.subscriptions_rounded,
      color: Color(0xFF673AB7),
      keywords: ['subscription', 'membership', 'premium', 'plan', 'movie', 'cinema', 'netflix', 'spotify', 'game', 'concert', 'theater', 'ticket', 'gym', 'fitness', 'apple music', 'apple tv', 'app store', 'itunes', 'google play', 'entertainment'],
    ),
    ExpenseCategory.education: CategoryInfo(
      category: ExpenseCategory.education,
      name: 'Education',
      emoji: '📚',
      icon: Icons.school_rounded,
      color: Color(0xFF3F51B5),
      keywords: ['school', 'tuition', 'course', 'book', 'education', 'learning', 'university', 'college'],
    ),
    ExpenseCategory.travel: CategoryInfo(
      category: ExpenseCategory.travel,
      name: 'Travel',
      emoji: '✈️',
      icon: Icons.flight_takeoff_rounded,
      color: Color(0xFF009688),
      keywords: ['hotel', 'travel', 'vacation', 'trip', 'booking', 'airbnb', 'flight', 'resort'],
    ),
    ExpenseCategory.other: CategoryInfo(
      category: ExpenseCategory.other,
      name: 'Other',
      emoji: '📦',
      icon: Icons.category_rounded,
      color: Color(0xFF9E9E9E),
      keywords: [],
    ),
  };
  
  static CategoryInfo getInfo(ExpenseCategory category) {
    return categories[category] ?? categories[ExpenseCategory.other]!;
  }

  /// Theme-driven category color (Material 3 friendly).
  ///
  /// Prefer this over [color] for UI so themes (including monochrome) stay consistent.
  static Color themedColor(BuildContext context, ExpenseCategory category) {
    final cs = Theme.of(context).colorScheme;
    switch (category) {
      case ExpenseCategory.housing:
        return cs.primary;
      case ExpenseCategory.food:
        return cs.secondary;
      case ExpenseCategory.transport:
        return cs.tertiary;
      case ExpenseCategory.health:
        return cs.error;
      case ExpenseCategory.lifestyle:
        return cs.primaryContainer;
      case ExpenseCategory.subscriptions:
        return cs.secondaryContainer;
      case ExpenseCategory.education:
        return cs.tertiaryContainer;
      case ExpenseCategory.travel:
        return cs.primary.withOpacity(0.85);
      case ExpenseCategory.other:
        return cs.outline;
    }
  }

  /// Maps an old category string or any string to the current ExpenseCategory enum
  static ExpenseCategory mapStringToCategory(String? name) {
    if (name == null || name.trim().isEmpty) return ExpenseCategory.other;
    final normalized = _normalizeCategoryText(name);

    // Fast-path enum names and legacy aliases.
    for (final value in ExpenseCategory.values) {
      if (value.name == normalized) return value;
    }
    final aliasCategory = _categoryAliases[normalized];
    if (aliasCategory != null) return aliasCategory;

    final tokens = normalized
        .split(' ')
        .where((token) => token.isNotEmpty && token.length > 1)
        .toSet();
    if (tokens.isEmpty) return ExpenseCategory.other;

    final scores = <ExpenseCategory, int>{};
    for (final entry in _categoryKeywordWeights.entries) {
      final category = entry.key;
      final weights = entry.value;
      var score = 0;

      for (final keywordEntry in weights.entries) {
        final keyword = keywordEntry.key;
        final weight = keywordEntry.value;

        // Phrase match has the highest confidence.
        if (keyword.contains(' ')) {
          if (normalized.contains(keyword)) {
            score += weight + 2;
          }
          continue;
        }

        // Exact token beats substring to reduce false positives.
        if (tokens.contains(keyword)) {
          score += weight + 1;
        } else if (normalized.contains(keyword)) {
          score += weight;
        }
      }

      if (score > 0) {
        scores[category] = score;
      }
    }

    if (scores.isEmpty) return ExpenseCategory.other;

    final sorted = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final best = sorted.first;
    final runnerUp = sorted.length > 1 ? sorted[1] : null;

    // Avoid weak single-keyword classifications.
    if (best.value <= 3) {
      return ExpenseCategory.other;
    }

    // If scores are too close, prefer "other" over random misclassification.
    if (runnerUp != null && (best.value - runnerUp.value) <= 1) {
      return ExpenseCategory.other;
    }

    return best.key;
  }

  static String _normalizeCategoryText(String input) {
    final lower = input.toLowerCase();
    final cleaned = lower.replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();
    return cleaned.replaceAll(RegExp(r'\s+'), ' ');
  }

  static const Map<String, ExpenseCategory> _categoryAliases = {
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

  // Higher values indicate stronger categorization evidence.
  static const Map<ExpenseCategory, Map<String, int>> _categoryKeywordWeights = {
    ExpenseCategory.housing: {
      'rent': 4,
      'mortgage': 4,
      'apartment': 3,
      'utility': 4,
      'utilities': 4,
      'electric': 3,
      'electricity': 4,
      'water': 3,
      'gas bill': 4,
      'internet': 3,
      'wifi': 3,
      'home insurance': 4,
      'insurance': 3,
      'bill': 2,
      'power': 3,
    },
    ExpenseCategory.food: {
      'grocery': 4,
      'groceries': 4,
      'supermarket': 4,
      'restaurant': 4,
      'cafe': 3,
      'coffee': 3,
      'dining': 4,
      'food': 3,
      'bakery': 3,
      'pizza': 3,
      'burger': 3,
      'walmart': 2,
      'costco': 2,
      'aldi': 2,
      'kroger': 2,
    },
    ExpenseCategory.transport: {
      'uber': 4,
      'lyft': 4,
      'taxi': 3,
      'fuel': 4,
      'petrol': 4,
      'gas station': 4,
      'parking': 3,
      'metro': 3,
      'bus': 3,
      'train': 3,
      'airline': 3,
      'flight': 2,
      'commute': 3,
    },
    ExpenseCategory.health: {
      'pharmacy': 4,
      'medicine': 4,
      'medical': 4,
      'doctor': 4,
      'hospital': 4,
      'clinic': 4,
      'dentist': 4,
      'vision': 3,
      'lab': 3,
      'health': 3,
    },
    ExpenseCategory.lifestyle: {
      'shopping': 4,
      'clothes': 4,
      'fashion': 3,
      'apparel': 3,
      'electronics': 4,
      'phone': 2,
      'laptop': 3,
      'computer': 3,
      'salon': 3,
      'barber': 3,
      'beauty': 3,
      'gift': 3,
      'store': 1,
      'mall': 2,
      'amazon': 2,
    },
    ExpenseCategory.subscriptions: {
      'subscription': 4,
      'membership': 4,
      'netflix': 5,
      'spotify': 5,
      'youtube premium': 5,
      'apple music': 5,
      'google play': 4,
      'itunes': 4,
      'app store': 4,
      'gym': 4,
      'fitness': 3,
      'streaming': 4,
      'entertainment': 3,
      'plan': 2,
    },
    ExpenseCategory.education: {
      'tuition': 5,
      'school': 4,
      'college': 4,
      'university': 4,
      'course': 4,
      'education': 4,
      'book': 2,
      'learning': 4,
      'udemy': 4,
      'coursera': 4,
    },
    ExpenseCategory.travel: {
      'hotel': 5,
      'airbnb': 5,
      'booking': 4,
      'trip': 2,
      'travel': 4,
      'vacation': 4,
      'resort': 4,
      'flight ticket': 4,
      'hostel': 4,
    },
  };
}
