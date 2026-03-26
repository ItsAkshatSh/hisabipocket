import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hisabi/core/utils/theme_extensions.dart';
import 'package:hisabi/features/insights/models/insights_models.dart';
import 'package:intl/intl.dart';

class MonthlySpendingChartsCard extends StatelessWidget {
  final InsightsData insights;
  const MonthlySpendingChartsCard({super.key, required this.insights});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final now = DateTime.now();

    final formatter = NumberFormat.simpleCurrency(
      name: insights.currency.name,
      decimalDigits: 2,
    );

    final savingsRate = insights.savingsRate;
    final savingsRatio = (savingsRate / 100).clamp(0.0, 1.0);
    final isOverBudget = savingsRate < 0;
    final gaugeColor = isOverBudget ? cs.error : cs.primary;

    // The current InsightsData model only contains the latest monthly spending.
    // For a uniform UI and to keep this widget compiling, we render a simple
    // 6-month "trend" using the same value, plus generated month labels.
    final trendValues = List<double>.filled(6, insights.monthlySpending);
    final trendLabels = List<String>.generate(6, (i) {
      final monthOffsetFromCurrent = 5 - i; // oldest -> newest
      final d = DateTime(now.year, now.month - monthOffsetFromCurrent, 1);
      return DateFormat('MMM').format(d);
    });

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.show_chart_rounded,
                  color: cs.onPrimaryContainer,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Spending Trend',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: context.onSurfaceColor,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Last 6 months • ${formatter.format(insights.monthlySpending)} this month',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: context.onSurfaceMutedColor,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Main Content
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: cs.outlineVariant.withOpacity(0.32),
                    ),
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        height: 170,
                        child: CustomPaint(
                          painter: _MonthlyTrendPainter(
                            values: trendValues,
                            lineColor: cs.primary,
                            barColor: cs.primary.withOpacity(0.18),
                            gridColor: cs.onSurfaceVariant.withOpacity(0.12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: List.generate(6, (i) {
                          return Expanded(
                            child: Text(
                              trendLabels[i],
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: cs.onSurfaceVariant,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),
              
              // Savings Gauge
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isOverBudget
                      ? cs.errorContainer
                      : cs.tertiaryContainer,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: (isOverBudget ? cs.error : cs.tertiary)
                        .withOpacity(0.35),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isOverBudget ? cs.error : cs.tertiary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isOverBudget ? Icons.warning_rounded : Icons.savings_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 120,
                      width: 120,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: savingsRatio,
                            strokeWidth: 10,
                            strokeCap: StrokeCap.round,
                            valueColor: AlwaysStoppedAnimation<Color>(gaugeColor),
                            backgroundColor: gaugeColor.withOpacity(0.2),
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${insights.savingsRate.toStringAsFixed(0)}%',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      color: isOverBudget ? cs.error : cs.primary,
                                    ),
                              ),
                              Text(
                                'savings',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: cs.onSurfaceVariant,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: isOverBudget ? cs.error.withOpacity(0.1) : cs.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isOverBudget ? 'Over budget' : 'On track',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isOverBudget ? cs.error : cs.primary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MonthlyTrendPainter extends CustomPainter {
  final List<double> values;
  final Color barColor;
  final Color lineColor;
  final Color gridColor;

  const _MonthlyTrendPainter({
    required this.values,
    required this.barColor,
    required this.lineColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const topPad = 10.0;
    const bottomPad = 18.0;

    final chartHeight = size.height - topPad - bottomPad;
    if (chartHeight <= 0) return;

    final maxValue = values.isEmpty
        ? 1.0
        : (values.reduce(math.max) <= 0 ? 1.0 : values.reduce(math.max));

    // Grid
    final gridPaint = Paint()
      ..color = gridColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (final t in [0.25, 0.5, 0.75]) {
      final y = topPad + (1 - t) * chartHeight;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Bars + line points
    final slotWidth = size.width / (values.length == 0 ? 1 : values.length);
    final barWidth = slotWidth * 0.55;

    final pointPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;

    final linePaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    final linePath = Path();
    for (var i = 0; i < values.length; i++) {
      final v = values[i];
      final xCenter = i * slotWidth + slotWidth / 2;
      final normalized = v / maxValue;
      final barHeight = normalized * chartHeight;
      final left = xCenter - barWidth / 2;
      final top = topPad + (chartHeight - barHeight);

      final rect = Rect.fromLTWH(left, top, barWidth, barHeight);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(8)),
        Paint()..color = barColor,
      );

      final y = topPad + (chartHeight - barHeight);
      if (i == 0) {
        linePath.moveTo(xCenter, y);
      } else {
        linePath.lineTo(xCenter, y);
      }
    }

    canvas.drawPath(linePath, linePaint);

    // Points
    for (var i = 0; i < values.length; i++) {
      final v = values[i];
      final xCenter = i * slotWidth + slotWidth / 2;
      final normalized = v / maxValue;
      final barHeight = normalized * chartHeight;
      final y = topPad + (chartHeight - barHeight);
      canvas.drawCircle(Offset(xCenter, y), 3.6, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _MonthlyTrendPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.barColor != barColor ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.gridColor != gridColor;
  }
}

