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
                  'You are a financial categorization assistant. Return only valid JSON. Use lowercase category names matching ExpenseCategory enum: housing, food, transport, health, lifestyle, subscriptions, education, travel, other.',
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

    for (final item in items) {
      final itemLower = item.toLowerCase();
      ExpenseCategory? category;

      // Use the updated CategoryInfo keywords
      for (final catEntry in CategoryInfo.categories.entries) {
        if (catEntry.value.keywords.any((keyword) => 
            itemLower.contains(keyword) || storeLower.contains(keyword))) {
          category = catEntry.key;
          break;
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
    required String currencyCode,
    List<Map<String, dynamic>>? recurringExpenses,
  }) async {
    try {
      final prompt =
          _buildBudgetPrompt(spendingHistory, monthlyIncome, monthsOfData, recurringExpenses, currencyCode);

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
                  'You are a financial planning assistant. Return only valid JSON with budget recommendations. Provide practical, realistic budget suggestions based on common financial wisdom (like the 50/30/20 rule) and the user\'s specific data.',
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
    String currency,
  ) {
    final spendingText = spending.entries
        .map((e) => '${e.key.name}: ${e.value.toStringAsFixed(2)}')
        .join('\n');
    
    final recurringText = recurring != null && recurring.isNotEmpty
        ? recurring.map((r) => '${r['name']}: ${r['amount']} (${r['frequency']})').join('\n')
        : 'None';

    return '''
Analyze spending patterns and suggest a practical, realistic monthly budget plan.

Monthly Income: $currency ${income.toStringAsFixed(2)}
Months of Data: $months

Current Spending by Category (Variable Expenses):
$spendingText

Recurring Expenses (Fixed Costs):
$recurringText

Return JSON format:
{
  "budgets": {
    "housing": amount,
    "food": amount,
    "transport": amount,
    "health": amount,
    "lifestyle": amount,
    "subscriptions": amount,
    "education": amount,
    "travel": amount,
    "other": amount
  },
  "savingsGoal": amount,
  "recommendations": ["tip1", "tip2", ...]
}

CRITICAL INSTRUCTIONS:
1. CURRENCY: All amounts in your response (budgets, savingsGoal) MUST be in $currency.
2. Suggested Budgets for ALL Categories: You MUST provide a unique budget amount for EVERY ONE of the 9 categories. Do not skip any.
3. Be Practical, Not Equal: Do NOT just divide the money equally. Allocate more to essentials (housing, food) and less to discretionary categories. 
4. Budget Optimization: If the user is overspending in a category, suggest a budget that is challenging but realistic, not just their current spending.
5. Baseline for Empty Categories: If current spending is zero, provide a small baseline buffer for that category.
6. Fixed Costs First: Ensure Housing and Subscriptions budgets are at least enough to cover the Recurring Expenses provided.
7. 50/30/20 Rule: Generally aim for 50% Essentials (Housing, Food, Transport, Health), 30% Lifestyle/Fun (Lifestyle, Subscriptions, Travel, Other, Education), and 20% Savings.
8. Balance the Books: Total of all budgets + savingsGoal MUST equal the Monthly Income.
''';
  }

  Map<String, dynamic> _defaultBudgetPlan(
    Map<ExpenseCategory, double> spending,
    double income,
  ) {
    final savingsGoal = income * 0.2; // 20% savings goal
    final remaining = income - savingsGoal;
    
    final allocations = {
      'housing': 0.35 * remaining,
      'food': 0.15 * remaining,
      'transport': 0.10 * remaining,
      'health': 0.05 * remaining,
      'lifestyle': 0.10 * remaining,
      'subscriptions': 0.05 * remaining,
      'education': 0.05 * remaining,
      'travel': 0.10 * remaining,
      'other': 0.05 * remaining,
    };

    return {
      'budgets': allocations,
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
    required String currencyCode,
  }) async {
    try {
      final prompt = _buildWrappedPrompt(stats, personality, funFacts, currencyCode);

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
                  'You are a creative financial storyteller. Generate engaging, fun narratives about spending patterns in a Spotify Wrapped style. Be concise, friendly, and use emojis. Use the correct currency code provided.',
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

    return _defaultNarrative(stats, personality, currencyCode);
  }

  String _buildWrappedPrompt(
    Map<String, dynamic> stats,
    String personality,
    List<String> funFacts,
    String currency,
  ) {
    return '''
Generate a fun, engaging narrative for a weekly spending wrap-up in Spotify Wrapped style.

Currency: $currency

Stats:
- Total spent: $currency ${stats['totalSpent']?.toStringAsFixed(2) ?? '0'}
- Receipts: ${stats['receiptsCount'] ?? 0}
- Top store: ${stats['topStore'] ?? 'N/A'}
- Top category: ${stats['topCategory'] ?? 'N/A'}
- Biggest purchase: $currency ${stats['biggestPurchaseAmount']?.toStringAsFixed(2) ?? '0'}
- Busiest day: ${stats['busiestDay'] ?? 'N/A'}

Personality: $personality

Fun facts: ${funFacts.join(', ')}

Create a short, engaging narrative (2-3 sentences) that makes spending tracking fun and interesting. Use emojis and be conversational. USE $currency FOR ALL MONETARY VALUES.
''';
  }

  String _defaultNarrative(Map<String, dynamic> stats, String personality, String currency) {
    final totalSpent = stats['totalSpent']?.toStringAsFixed(2) ?? '0';
    final receiptsCount = stats['receiptsCount'] ?? 0;
    final topStore = stats['topStore'] ?? 'various stores';

    return 'You spent $currency $totalSpent across $receiptsCount ${receiptsCount == 1 ? 'receipt' : 'receipts'} this week! Your top spending was at $topStore. $personality';
  }
}
