import 'package:hisabi/core/models/category_model.dart';
import 'package:hisabi/core/services/ai_service.dart';

/// Legacy quick-add parser kept for backwards compatibility.
///
/// Newer code should call `AIService.parseQuickAddText(...)` directly, but
/// older screens (like `VoiceQuickAddScreen`) still reference:
/// - `QuickAddParseResult`
/// - `parseQuickAdd(...)`

class QuickAddParseResult {
  final double amount;
  final String description;
  final DateTime? date;
  final ExpenseCategory category;
  final String notes;

  const QuickAddParseResult({
    required this.amount,
    required this.description,
    required this.date,
    required this.category,
    required this.notes,
  });
}

/// Parses a "quick add" string like `20 for groceries`.
///
/// Returns `null` when the input doesn't contain a usable amount.
QuickAddParseResult? parseQuickAdd(
  String input, {
  DateTime? now,
}) {
  final draft = AIService().parseQuickAddText(
    input,
    now: now,
  );

  // Voice quick-add needs a concrete amount for saving.
  final amount = draft.amount;
  if (amount == null) return null;

  return QuickAddParseResult(
    amount: amount,
    description: draft.merchant,
    date: draft.date,
    category: draft.category,
    notes: draft.notes,
  );
}
