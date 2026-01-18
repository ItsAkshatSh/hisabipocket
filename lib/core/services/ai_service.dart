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
                  'You are a financial categorization assistant. Return only valid JSON. Use lowercase category names matching ExpenseCategory enum: groceries, dining, transportation, utilities, rent, healthcare, insurance, entertainment, shopping, clothing, personalCare, subscriptions, travel, education, gifts, other.',
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

Available categories: groceries, dining, transportation, utilities, rent, healthcare, insurance, entertainment, shopping, clothing, personalCare, subscriptions, travel, education, gifts, other

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

      // Check store-based categorization first
      if (storeLower.contains('grocery') ||
          storeLower.contains('market') ||
          storeLower.contains('walmart') ||
          storeLower.contains('target') ||
          storeLower.contains('costco') ||
          storeLower.contains('safeway')) {
        category = ExpenseCategory.groceries;
      } else if (storeLower.contains('restaurant') ||
          storeLower.contains('cafe') ||
          storeLower.contains('mcdonalds') ||
          storeLower.contains('starbucks') ||
          storeLower.contains('pizza') ||
          storeLower.contains('burger')) {
        category = ExpenseCategory.dining;
      } else {
        // Check item keywords
        for (final catInfo in CategoryInfo.categories.values) {
          if (catInfo.keywords.any((keyword) => itemLower.contains(keyword))) {
            category = catInfo.category;
            break;
          }
        }
      }

      result[item] = category ?? ExpenseCategory.other;
    }

    return result;
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

  /// Generate budget recommendations
  Future<Map<String, dynamic>> generateBudgetPlan({
    required Map<ExpenseCategory, double> spendingHistory,
    required double monthlyIncome,
    required int monthsOfData,
  }) async {
    try {
      final prompt =
          _buildBudgetPrompt(spendingHistory, monthlyIncome, monthsOfData);

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
                  'You are a financial planning assistant. Return only valid JSON with budget recommendations.',
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
  ) {
    final spendingText = spending.entries
        .map((e) => '${e.key.name}: ${e.value.toStringAsFixed(2)}')
        .join('\n');

    return '''
Analyze spending patterns and suggest a monthly budget plan.

Monthly Income: \$${income.toStringAsFixed(2)}
Months of Data: $months

Current Spending by Category:
$spendingText

Return JSON format:
{
  "budgets": {
    "category_name": budgeted_amount,
    ...
  },
  "savingsGoal": amount,
  "recommendations": ["tip1", "tip2", ...]
}
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
        'Review subscriptions regularly',
        'Set spending limits for dining out',
      ],
    };
  }
}
