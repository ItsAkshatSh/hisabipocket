import 'package:flutter/material.dart';
import 'package:hisabi/core/utils/theme_extensions.dart';
import 'package:hisabi/features/insights/models/insights_models.dart';

class AIInsightsCard extends StatelessWidget {
  final InsightsData insights;
  
  const AIInsightsCard({super.key, required this.insights});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: context.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.psychology_outlined,
                    color: context.primaryColor,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Insights',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: context.onSurfaceColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Personalized financial insights',
                        style: TextStyle(
                          fontSize: 14,
                          color: context.onSurfaceMutedColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            if (insights.insights.isEmpty)
              Text(
                'Add more receipts to get personalized insights!',
                style: TextStyle(
                  fontSize: 14,
                  color: context.onSurfaceMutedColor,
                  fontStyle: FontStyle.italic,
                ),
              )
            else
              ...insights.insights.map((insight) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: context.primaryColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        insight,
                        style: TextStyle(
                          fontSize: 14,
                          color: context.onSurfaceColor,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
          ],
        ),
      ),
    );
  }
}

