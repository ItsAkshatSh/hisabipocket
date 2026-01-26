import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisabi/features/insights/providers/insights_provider.dart';
import 'package:hisabi/features/insights/providers/spending_alerts_provider.dart';
import 'package:hisabi/features/insights/providers/period_comparison_provider.dart';
import 'package:hisabi/features/insights/widgets/quick_stats_header.dart';
import 'package:hisabi/features/insights/widgets/spending_alerts_card.dart';
import 'package:hisabi/features/insights/widgets/period_comparison_card.dart';
import 'package:hisabi/features/insights/widgets/budget_planner_card.dart';
import 'package:hisabi/features/insights/widgets/ai_insights_card.dart';
import 'package:hisabi/features/insights/widgets/spending_analysis_card.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insightsAsync = ref.watch(insightsProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar.large(
            title: Text('AI Insights'),
            centerTitle: false,
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: insightsAsync.when(
              data: (insights) => SliverList(
                delegate: SliverChildListDelegate([
                  QuickStatsHeader(insights: insights),
                  const SizedBox(height: 24),
                  
                  // Alerts - Spending Alerts are perfect here
                  ref.watch(spendingAlertsProvider).maybeWhen(
                    data: (alerts) => alerts.isEmpty ? const SizedBox.shrink() : Column(
                      children: [
                        SpendingAlertsCard(alerts: alerts),
                        const SizedBox(height: 24),
                      ],
                    ),
                    orElse: () => const SizedBox.shrink(),
                  ),
                  
                  // Comparison
                  ref.watch(periodComparisonProvider).maybeWhen(
                    data: (comp) => comp == null ? const SizedBox.shrink() : Column(
                      children: [
                        PeriodComparisonCard(comparison: comp),
                        const SizedBox(height: 24),
                      ],
                    ),
                    orElse: () => const SizedBox.shrink(),
                  ),

                  BudgetPlannerCard(insights: insights),
                  const SizedBox(height: 24),
                  AIInsightsCard(insights: insights),
                  const SizedBox(height: 24),
                  SpendingAnalysisCard(insights: insights),
                  const SizedBox(height: 100),
                ]),
              ),
              loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
              error: (err, stack) => const SliverFillRemaining(child: Center(child: Text('Error loading insights'))),
            ),
          ),
        ],
      ),
    );
  }
}
