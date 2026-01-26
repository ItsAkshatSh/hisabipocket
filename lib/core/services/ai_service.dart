import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hisabi/core/models/category_model.dart';

class AIService {
  static String get _apiKey => dotenv.get('AI_API_KEY', fallback: '');
  static String get _baseUrl =>
      dotenv.get('AI_BASE_URL', fallback: 'https://ai.hackclub.com/proxy/v1');
  static const String _defaultModel = 'google/gemini-3-flash-preview';

  /// Categorize receipt items using AI
  Future<Map<String, ExpenseCategory>> categorizeItems({
    required List<String> itemNames,
    required String storeName,
    double? totalAmount,
  }) async {
    try {
      final prompt =
          _buildCategorizationPrompt(itemNames, storeName, totalAmount);

      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': _defaultModel,
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are a financial categorization assistant. Return only valid JSON. Use lowercase category names matching ExpenseCategory enum: housing, food, transport, health, lifestyle, subscriptions, education, travel, other. IMPORTANT RULES: 1) "apple" (fruit) -> food. 2) PHYSICAL PRODUCTS (hardware, devices, electronics, phones, laptops) -> lifestyle. 3) SERVICES/SUBSCRIPTIONS (monthly plans, streaming services, cloud storage, app subscriptions) -> subscriptions. Distinguish based on whether it is a physical product (lifestyle) or a service/subscription (subscriptions). Use item description and store context to determine.',
            },
            {
              'role': 'user',
              'content': prompt,
            },
          ],
          'response_format': {'type': 'json_object'},
          'temperature': 0.3,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        return _parseCategorizationResponse(content, itemNames);
      }
    } catch (e) {
      print('AI categorization error: $e');
    }

    // Fallback to rule-based categorization
    return _fallbackCategorization(itemNames, storeName);
  }

  String _buildCategorizationPrompt(
    List<String> items,
    String store,
    double? total,
  ) {
    return '''
Categorize these receipt items into expense categories. Return JSON format:
{
  "items": {
    "item_name": "category_name",
    ...
  }
}

Available categories: housing, food, transport, health, lifestyle, subscriptions, education, travel, other

IMPORTANT CONTEXT RULES:
- "apple" (the fruit) should be categorized as "food", not "subscriptions"
- PHYSICAL PRODUCTS (hardware, devices, electronics) from any store should be "lifestyle", not "subscriptions"
- SERVICES and SUBSCRIPTIONS (monthly plans, streaming, cloud storage, app subscriptions) should be "subscriptions"
- Consider the store name: Electronics/tech stores typically sell physical products = "lifestyle"
- Consider item description: Words like "subscription", "monthly", "plan", "premium", "streaming" indicate "subscriptions"
- Consider item description: Words like "device", "hardware", "phone", "laptop", "watch" indicate physical products = "lifestyle"
- Grocery stores/supermarkets indicate food items
- Subscriptions are recurring services, not physical products
- Physical electronics and devices are "lifestyle", not "subscriptions"

Items: ${items.join(', ')}
Store: $store
Total: ${total?.toStringAsFixed(2) ?? 'N/A'}

Return only the JSON object, no other text.
''';
  }

  Map<String, ExpenseCategory> _parseCategorizationResponse(
    String jsonContent,
    List<String> itemNames,
  ) {
    try {
      final data = jsonDecode(jsonContent);
      final items = data['items'] as Map<String, dynamic>?;
      if (items == null) return _fallbackCategorization(itemNames, '');

      final result = <String, ExpenseCategory>{};

      for (final entry in items.entries) {
        final categoryName = entry.value.toString().toLowerCase();
        final category = ExpenseCategory.values.firstWhere(
          (c) => c.name == categoryName,
          orElse: () => ExpenseCategory.other,
        );
        result[entry.key] = category;
      }

      // Ensure all items are categorized
      for (final item in itemNames) {
        if (!result.containsKey(item)) {
          result[item] = ExpenseCategory.other;
        }
      }

      return result;
    } catch (e) {
      print('Error parsing AI response: $e');
      return _fallbackCategorization(itemNames, '');
    }
  }

  Map<String, ExpenseCategory> _fallbackCategorization(
    List<String> items,
    String store,
  ) {
    final result = <String, ExpenseCategory>{};
    final storeLower = store.toLowerCase();
    final isGroceryStore = storeLower.contains('grocery') || 
                          storeLower.contains('supermarket') ||
                          storeLower.contains('walmart') ||
                          storeLower.contains('target') ||
                          storeLower.contains('kroger') ||
                          storeLower.contains('safeway') ||
                          storeLower.contains('whole foods') ||
                          storeLower.contains('aldi') ||
                          storeLower.contains('costco');

    for (final item in items) {
      final itemLower = item.toLowerCase();
      ExpenseCategory? category;

      // Special handling for "apple" - check context
      if (itemLower == 'apple' || itemLower.startsWith('apple ')) {
        // If it's a grocery store, it's likely the fruit
        if (isGroceryStore) {
          category = ExpenseCategory.food;
        } else {
          // Check if it's a service/subscription vs physical product
          final isService = itemLower.contains('music') ||
                           itemLower.contains('tv') ||
                           itemLower.contains('streaming') ||
                           itemLower.contains('subscription') ||
                           itemLower.contains('plan') ||
                           itemLower.contains('premium') ||
                           itemLower.contains('cloud') ||
                           itemLower.contains('storage');
          
          final isPhysicalProduct = itemLower.contains('device') ||
                                   itemLower.contains('hardware') ||
                                   itemLower.contains('phone') ||
                                   itemLower.contains('laptop') ||
                                   itemLower.contains('watch') ||
                                   itemLower.contains('tablet') ||
                                   itemLower.contains('computer') ||
                                   storeLower.contains('store') && !storeLower.contains('subscription');
          
          if (isService) {
            category = ExpenseCategory.subscriptions;
          } else if (isPhysicalProduct) {
            category = ExpenseCategory.lifestyle;
          } else {
            // Default to food if uncertain (safer assumption for fruit)
            category = ExpenseCategory.food;
          }
        }
      } else {
        // Check if item is a service/subscription vs physical product
        final isService = itemLower.contains('subscription') ||
                         itemLower.contains('monthly') ||
                         itemLower.contains('plan') ||
                         itemLower.contains('premium') ||
                         itemLower.contains('streaming') ||
                         itemLower.contains('music service') ||
                         itemLower.contains('tv service') ||
                         itemLower.contains('cloud storage');
        
        final isPhysicalProduct = itemLower.contains('device') ||
                                 itemLower.contains('hardware') ||
                                 itemLower.contains('phone') ||
                                 itemLower.contains('laptop') ||
                                 itemLower.contains('watch') ||
                                 itemLower.contains('tablet') ||
                                 itemLower.contains('computer') ||
                                 itemLower.contains('electronics');
        
        // Prioritize service/product detection over keyword matching
        if (isService && !isPhysicalProduct) {
          category = ExpenseCategory.subscriptions;
        } else if (isPhysicalProduct && !isService) {
          category = ExpenseCategory.lifestyle;
        } else {
          // Use the updated CategoryInfo keywords
          for (final catEntry in CategoryInfo.categories.entries) {
            if (catEntry.value.keywords.any((keyword) => 
                itemLower.contains(keyword) || storeLower.contains(keyword))) {
              category = catEntry.key;
              break;
            }
          }
        }
      }

      result[item] = category ?? ExpenseCategory.other;
    }

    return result;
  }

  /// Generate budget recommendations
  Future<Map<String, dynamic>> generateBudgetPlan({
    required Map<ExpenseCategory, double> spendingHistory,
    required double monthlyIncome,
    required int monthsOfData,
    List<Map<String, dynamic>>? recurringExpenses,
  }) async {
    try {
      final prompt =
          _buildBudgetPrompt(spendingHistory, monthlyIncome, monthsOfData, recurringExpenses);

      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': _defaultModel,
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are a financial planning assistant. Return only valid JSON with budget recommendations. Ensure each category appears only once in the results.',
            },
            {
              'role': 'user',
              'content': prompt,
            },
          ],
          'response_format': {'type': 'json_object'},
          'temperature': 0.5,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return jsonDecode(data['choices'][0]['message']['content']);
      }
    } catch (e) {
      print('AI budget generation error: $e');
    }

    return _defaultBudgetPlan(spendingHistory, monthlyIncome);
  }

  String _buildBudgetPrompt(
    Map<ExpenseCategory, double> spending,
    double income,
    int months,
    List<Map<String, dynamic>>? recurring,
  ) {
    final spendingText = spending.entries
        .map((e) => '${e.key.name}: ${e.value.toStringAsFixed(2)}')
        .join('\n');
    
    final recurringText = recurring != null && recurring.isNotEmpty
        ? recurring.map((r) => '${r['name']}: ${r['amount']} (${r['frequency']})').join('\n')
        : 'None';

    return '''
Analyze spending patterns and suggest a monthly budget plan.

Monthly Income: \$${income.toStringAsFixed(2)}
Months of Data: $months

Current Spending by Category:
$spendingText

Recurring Expenses (Fixed Costs):
$recurringText

Return JSON format:
{
  "budgets": {
    "category_name": budgeted_amount,
    ...
  },
  "savingsGoal": amount,
  "recommendations": ["tip1", "tip2", ...]
}

IMPORTANT:
1. Ensure category names in "budgets" are unique and MUST be exactly one of these: housing, food, transport, health, lifestyle, subscriptions, education, travel, other.
2. Incorporate the recurring expenses into these categories (e.g., Netflix -> subscriptions, Rent -> housing).
3. Do not create sub-categories. Only use the 9 categories listed above.
''';
  }

  Map<String, dynamic> _defaultBudgetPlan(
    Map<ExpenseCategory, double> spending,
    double income,
  ) {
    final savingsGoal = income * 0.2; // 20% savings goal

    final budgets = <String, double>{};
    for (final entry in spending.entries) {
      budgets[entry.key.name] = entry.value;
    }

    return {
      'budgets': budgets,
      'savingsGoal': savingsGoal,
      'recommendations': [
        'Try to save 20% of your income',
        'Review your subscriptions regularly',
        'Consider these 9 simplified categories for better tracking',
      ],
    };
  }

  /// Generate weekly wrapped insights
  Future<String> generateWrappedNarrative({
    required Map<String, dynamic> stats,
    required String personality,
    required List<String> funFacts,
  }) async {
    try {
      final prompt = _buildWrappedPrompt(stats, personality, funFacts);

      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': _defaultModel,
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are a creative financial storyteller. Generate engaging, fun narratives about spending patterns in a Spotify Wrapped style. Be concise, friendly, and use emojis.',
            },
            {
              'role': 'user',
              'content': prompt,
            },
          ],
          'temperature': 0.8,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      }
    } catch (e) {
      print('AI narrative generation error: $e');
    }

    return _defaultNarrative(stats, personality);
  }

  String _buildWrappedPrompt(
    Map<String, dynamic> stats,
    String personality,
    List<String> funFacts,
  ) {
    return '''
Generate a fun, engaging narrative for a weekly spending wrap-up in Spotify Wrapped style.

Stats:
- Total spent: \$${stats['totalSpent']?.toStringAsFixed(2) ?? '0'}
- Receipts: ${stats['receiptsCount'] ?? 0}
- Top store: ${stats['topStore'] ?? 'N/A'}
- Top category: ${stats['topCategory'] ?? 'N/A'}
- Biggest purchase: \$${stats['biggestPurchaseAmount']?.toStringAsFixed(2) ?? '0'}
- Busiest day: ${stats['busiestDay'] ?? 'N/A'}

Personality: $personality

Fun facts: ${funFacts.join(', ')}

Create a short, engaging narrative (2-3 sentences) that makes spending tracking fun and interesting. Use emojis and be conversational.
''';
  }

  String _defaultNarrative(Map<String, dynamic> stats, String personality) {
    final totalSpent = stats['totalSpent']?.toStringAsFixed(2) ?? '0';
    final receiptsCount = stats['receiptsCount'] ?? 0;
    final topStore = stats['topStore'] ?? 'various stores';

    return 'You spent \$$totalSpent across $receiptsCount ${receiptsCount == 1 ? 'receipt' : 'receipts'} this week! Your top spending was at $topStore. $personality';
  }
}
