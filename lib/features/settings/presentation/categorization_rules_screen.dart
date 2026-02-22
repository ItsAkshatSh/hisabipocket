import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisabi/core/models/category_model.dart';
import 'package:hisabi/features/settings/models/categorization_rule_model.dart';
import 'package:hisabi/features/settings/providers/categorization_rules_provider.dart';

class CategorizationRulesScreen extends ConsumerWidget {
  const CategorizationRulesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rulesAsync = ref.watch(categorizationRulesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Categorization Rules'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddRuleDialog(context, ref),
          ),
        ],
      ),
      body: rulesAsync.when(
        data: (rules) {
          if (rules.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.rule_outlined, size: 64, color: Theme.of(context).colorScheme.outline),
                  const SizedBox(height: 16),
                  Text(
                    'No rules yet',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create rules to automatically categorize receipts',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => _showAddRuleDialog(context, ref),
                    child: const Text('Add Rule'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: rules.length,
            itemBuilder: (context, index) {
              final rule = rules[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: CategoryInfo.getInfo(rule.category).color.withOpacity(0.2),
                    child: Text(
                      CategoryInfo.getInfo(rule.category).emoji,
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                  title: Text(
                    rule.pattern,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      decoration: rule.isActive ? null : TextDecoration.lineThrough,
                    ),
                  ),
                  subtitle: Text(
                    '${rule.matchType.name} → ${CategoryInfo.getInfo(rule.category).name}',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: rule.isActive,
                        onChanged: (_) => ref.read(categorizationRulesProvider.notifier).toggleRule(rule.id),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _confirmDelete(context, ref, rule),
                      ),
                    ],
                  ),
                  onTap: () => _showEditRuleDialog(context, ref, rule),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  void _showAddRuleDialog(BuildContext context, WidgetRef ref) {
    _showRuleDialog(context, ref, null);
  }

  void _showEditRuleDialog(BuildContext context, WidgetRef ref, CategorizationRule rule) {
    _showRuleDialog(context, ref, rule);
  }

  void _showRuleDialog(BuildContext context, WidgetRef ref, CategorizationRule? rule) {
    final patternController = TextEditingController(text: rule?.pattern ?? '');
    RuleMatchType selectedMatchType = rule?.matchType ?? RuleMatchType.both;
    ExpenseCategory selectedCategory = rule?.category ?? ExpenseCategory.other;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(rule == null ? 'Add Rule' : 'Edit Rule'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: patternController,
                  decoration: const InputDecoration(
                    labelText: 'Pattern (text to match)',
                    hintText: 'e.g., Starbucks, Coffee, etc.',
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<RuleMatchType>(
                  initialValue: selectedMatchType,
                  decoration: const InputDecoration(labelText: 'Match Type'),
                  items: RuleMatchType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type.name.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedMatchType = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<ExpenseCategory>(
                  initialValue: selectedCategory,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: ExpenseCategory.values.map((category) {
                    final info = CategoryInfo.getInfo(category);
                    return DropdownMenuItem(
                      value: category,
                      child: Row(
                        children: [
                          Text(info.emoji),
                          const SizedBox(width: 8),
                          Text(info.name),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedCategory = value);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (patternController.text.isNotEmpty) {
                  final newRule = rule == null
                      ? CategorizationRule(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          pattern: patternController.text,
                          matchType: selectedMatchType,
                          category: selectedCategory,
                        )
                      : rule.copyWith(
                          pattern: patternController.text,
                          matchType: selectedMatchType,
                          category: selectedCategory,
                        );

                  if (rule == null) {
                    ref.read(categorizationRulesProvider.notifier).addRule(newRule);
                  } else {
                    ref.read(categorizationRulesProvider.notifier).updateRule(newRule);
                  }
                  Navigator.pop(context);
                }
              },
              child: Text(rule == null ? 'Add' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, CategorizationRule rule) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Rule?'),
        content: Text('Are you sure you want to delete the rule "${rule.pattern}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(categorizationRulesProvider.notifier).deleteRule(rule.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

