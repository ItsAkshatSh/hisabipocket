import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisabi/features/insights/providers/insights_provider.dart';
import 'package:hisabi/features/insights/providers/spending_alerts_provider.dart';
import 'package:hisabi/features/insights/providers/period_comparison_provider.dart';
import 'package:hisabi/features/insights/widgets/insights_hero_header.dart';
import 'package:hisabi/features/insights/widgets/insights_section_header.dart';
import 'package:hisabi/features/insights/widgets/premium_category_breakdown.dart';
import 'package:hisabi/features/insights/widgets/premium_ai_insights_card.dart';
import 'package:hisabi/features/insights/widgets/premium_savings_card.dart';
import 'package:hisabi/features/insights/widgets/spending_alerts_card.dart';
import 'package:hisabi/features/insights/widgets/period_comparison_card.dart';
import 'package:hisabi/features/insights/widgets/budget_planner_card.dart';
import 'package:hisabi/features/insights/widgets/subscription_detective_card.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insightsAsync = ref.watch(insightsProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: cs.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Modern App Bar
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            pinned: true,
            elevation: 0,
            backgroundColor: cs.background,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: Text(
                'Insights',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: cs.onBackground,
                ),
              ),
            ),
            actions: [
              IconButton(
                onPressed: () => ref.invalidate(insightsProvider),
                icon: Icon(
                  Icons.refresh_rounded,
                  color: cs.onBackground,
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),

          // Main Content
          SliverPadding(
            padding: const EdgeInsets.only(top: 8, bottom: 32),
            sliver: insightsAsync.when(
              data: (insights) => SliverList(
                delegate: SliverChildListDelegate([
                  // Hero Header with Total Spending
                  InsightsHeroHeader(insights: insights),
                  const SizedBox(height: 32),

                  // Spending Alerts (if any)
                  ref.watch(spendingAlertsProvider).maybeWhen(
                    data: (alerts) => alerts.isEmpty
                        ? const SizedBox.shrink()
                        : Column(
                            children: [
                              const InsightsSectionHeader(
                                title: 'Alerts',
                                subtitle: 'Items needing attention',
                                icon: Icons.notifications_outlined,
                              ),
                              SpendingAlertsCard(alerts: alerts),
                              const SizedBox(height: 32),
                            ],
                          ),
                    orElse: () => const SizedBox.shrink(),
                  ),

                  // Category Breakdown Section
                  const InsightsSectionHeader(
                    title: 'Spending Breakdown',
                    subtitle: 'Where your money goes',
                    icon: Icons.pie_chart_outline,
                  ),
                  PremiumCategoryBreakdown(insights: insights),
                  const SizedBox(height: 32),

                  // Savings & Budget Section
                  const InsightsSectionHeader(
                    title: 'Savings & Budget',
                    subtitle: 'Financial health overview',
                    icon: Icons.savings_outlined,
                  ),
                  PremiumSavingsCard(insights: insights),
                  const SizedBox(height: 32),

                  // Period Comparison (if available)
                  ref.watch(periodComparisonProvider).maybeWhen(
                    data: (comp) => comp == null
                        ? const SizedBox.shrink()
                        : Column(
                            children: [
                              const InsightsSectionHeader(
                                title: 'Period Comparison',
                                subtitle: 'Month over month',
                                icon: Icons.compare_arrows_outlined,
                              ),
                              PeriodComparisonCard(comparison: comp),
                              const SizedBox(height: 32),
                            ],
                          ),
                    orElse: () => const SizedBox.shrink(),
                  ),

                  // AI Insights Section
                  const InsightsSectionHeader(
                    title: 'Smart Insights',
                    subtitle: 'AI-powered recommendations',
                    icon: Icons.auto_awesome_outlined,
                  ),
                  PremiumAIInsightsCard(insights: insights),
                  const SizedBox(height: 32),

                  // Budget Planner
                  const InsightsSectionHeader(
                    title: 'Budget Planner',
                    subtitle: 'Personalized budget suggestions',
                    icon: Icons.account_balance_wallet_outlined,
                  ),
                  BudgetPlannerCard(insights: insights),
                  const SizedBox(height: 32),

                  // Subscription Detective
                  const InsightsSectionHeader(
                    title: 'Subscriptions',
                    subtitle: 'Track recurring payments',
                    icon: Icons.subscriptions_outlined,
                  ),
                  const SubscriptionDetectiveCard(),
                  const SizedBox(height: 40),
                ]),
              ),
              loading: () => SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 48,
                        height: 48,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Analyzing your finances…',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              error: (err, stack) => SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: cs.errorContainer.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.cloud_off_rounded,
                            size: 40,
                            color: cs.error,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Couldn\'t load insights',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Check your connection and try again.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 24),
                        FilledButton.icon(
                          onPressed: () => ref.invalidate(insightsProvider),
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Try Again'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
