import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisabi/core/utils/theme_extensions.dart';
import 'package:hisabi/features/insights/providers/insights_provider.dart';
import 'package:hisabi/features/insights/widgets/budget_planner_card.dart';
import 'package:hisabi/features/insights/widgets/ai_insights_card.dart';
import 'package:hisabi/features/insights/widgets/spending_analysis_card.dart';
import 'package:intl/intl.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insightsAsync = ref.watch(insightsProvider);
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: isMobile ? 20.0 : 32.0,
          right: isMobile ? 20.0 : 32.0,
          top: isMobile ? 20.0 : 32.0,
          bottom: isMobile ? 100.0 : 32.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'AI Insights & Budgeting',
              style: TextStyle(
                fontSize: isMobile ? 28 : 36,
                fontWeight: FontWeight.bold,
                color: context.onSurfaceColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Get personalized financial insights and plan your budget',
              style: TextStyle(
                fontSize: 16,
                color: context.onSurfaceMutedColor,
              ),
            ),
            const SizedBox(height: 32),
            
            // Insights content
            insightsAsync.when(
              data: (insights) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Budget Planner Card
                  BudgetPlannerCard(insights: insights),
                  const SizedBox(height: 24),
                  
                  // AI Insights Card
                  AIInsightsCard(insights: insights),
                  const SizedBox(height: 24),
                  
                  // Spending Analysis Card
                  SpendingAnalysisCard(insights: insights),
                ],
              ),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: context.errorColor,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading insights',
                        style: TextStyle(
                          fontSize: 18,
                          color: context.onSurfaceColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        error.toString(),
                        style: TextStyle(
                          fontSize: 14,
                          color: context.onSurfaceMutedColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

