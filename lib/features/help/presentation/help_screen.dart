import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar.large(
            title: Text('Help & Tips'),
            centerTitle: false,
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 12),
                _buildSectionHeader(context, 'Getting started'),
                const SizedBox(height: 16),
                const _HelpCard(
                  children: [
                    _HelpTile(
                      question: 'How do I add a receipt?',
                      answer:
                          'Go to the Dashboard and tap "Add receipt". You can enter items manually or use the voice quick-add screen. Hisabi will try to categorize items for you automatically.',
                    ),
                    Divider(height: 1),
                    _HelpTile(
                      question: 'What does the "Voice quick add" do?',
                      answer:
                          'Voice quick add lets you quickly log a simple expense by speaking, without filling all receipt details. It\'s great for on-the-go tracking.',
                    ),
                    Divider(height: 1),
                    _HelpTile(
                      question: 'How do I view my saved receipts?',
                      answer:
                          'Tap "Saved receipts" from the Dashboard to see all your past receipts. You can search, filter, and view details for any receipt.',
                    ),
                  ],
                ).animate().fadeIn().slideY(begin: 0.1),
                const SizedBox(height: 32),
                _buildSectionHeader(context, 'Insights & wrapped'),
                const SizedBox(height: 16),
                const _HelpCard(
                  children: [
                    _HelpTile(
                      question: 'How are my insights calculated?',
                      answer:
                          'Hisabi groups your spending by category using your receipts and recurring payments. We estimate income and highlight top categories, savings rate, and unusual activity.',
                    ),
                    Divider(height: 1),
                    _HelpTile(
                      question: 'What is "Weekly wrapped"?',
                      answer:
                          'Weekly wrapped is a fun summary of your last week of spending, showing top stores, categories, and interesting patterns in a story-like format.',
                    ),
                    Divider(height: 1),
                    _HelpTile(
                      question: 'How do budgets work?',
                      answer:
                          'Set monthly budgets for each category in Settings. Hisabi tracks your spending against these budgets and shows progress in the Insights screen.',
                    ),
                  ],
                ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
                const SizedBox(height: 32),
                _buildSectionHeader(context, 'Privacy & data'),
                const SizedBox(height: 16),
                const _HelpCard(
                  children: [
                    _HelpTile(
                      question: 'How is my data stored?',
                      answer:
                          'Your data is stored securely using Firebase. Only you can access your receipts and financial profile when signed in.',
                    ),
                    Divider(height: 1),
                    _HelpTile(
                      question: 'Can I export my data?',
                      answer:
                          'Yes! Go to Settings → Export Data to download your receipts as CSV or PDF files.',
                    ),
                    Divider(height: 1),
                    _HelpTile(
                      question: 'What about my financial profile?',
                      answer:
                          'Your income, recurring payments, and savings goals are stored securely and only used to provide better insights and budget recommendations.',
                    ),
                  ],
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
                const SizedBox(height: 120),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w900,
            color: Theme.of(context).colorScheme.primary,
            letterSpacing: 1.2,
          ),
    ).animate().fadeIn().slideX(begin: -0.1);
  }
}

class _HelpCard extends StatelessWidget {
  final List<Widget> children;

  const _HelpCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.3),
        ),
      ),
      child: Column(children: children),
    );
  }
}

class _HelpTile extends StatefulWidget {
  final String question;
  final String answer;

  const _HelpTile({
    required this.question,
    required this.answer,
  });

  @override
  State<_HelpTile> createState() => _HelpTileState();
}

class _HelpTileState extends State<_HelpTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ExpansionTile(
      title: Text(
        widget.question,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 15,
        ),
      ),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.help_outline,
          color: colorScheme.primary,
          size: 22,
        ),
      ),
      trailing: Icon(
        _isExpanded ? Icons.expand_less : Icons.expand_more,
        size: 20,
      ),
      onExpansionChanged: (expanded) {
        setState(() {
          _isExpanded = expanded;
        });
      },
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Text(
            widget.answer,
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}

