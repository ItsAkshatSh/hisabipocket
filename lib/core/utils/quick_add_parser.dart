class QuickAddParseResult {
  final double amount;
  final String description;

  QuickAddParseResult({required this.amount, required this.description});
}

/// Parse inputs like "20 for groceries" or "10 dhs for coke"
QuickAddParseResult? parseQuickAdd(String input) {
  final lower = input.toLowerCase().trim();

  // Remove currency words like "dhs" / "dh"
  final cleaned = lower.replaceAll(RegExp(r'\bdhs?\b'), '').trim();

  final match =
      RegExp(r'^(\d+(\.\d+)?)\s*(for)?\s*(.+)$').firstMatch(cleaned);
  if (match == null) return null;

  final amountStr = match.group(1)!;
  final desc = match.group(4)!.trim();

  final amount = double.tryParse(amountStr);
  if (amount == null || desc.isEmpty) return null;

  return QuickAddParseResult(amount: amount, description: desc);
}












