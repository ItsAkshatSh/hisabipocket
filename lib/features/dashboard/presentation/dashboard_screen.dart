import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:hisabi/core/utils/theme_extensions.dart';
import 'package:hisabi/core/widgets/fade_in_widget.dart';
import 'package:hisabi/core/widgets/shimmer_loading.dart';
import 'package:hisabi/core/widgets/animated_counter.dart';
import 'package:hisabi/features/dashboard/providers/dashboard_provider.dart';
import 'package:hisabi/features/dashboard/providers/wrapped_prompt_provider.dart';
import 'package:hisabi/features/receipts/presentation/widgets/receipt_details_modal.dart';
import 'package:hisabi/features/receipts/providers/receipts_store.dart';
import 'package:hisabi/features/settings/providers/settings_provider.dart';
import 'package:hisabi/core/models/receipt_summary_model.dart';
import 'package:hive_flutter/hive_flutter.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(periodProvider);
    final settingsAsync = ref.watch(settingsProvider);
    final currency = settingsAsync.valueOrNull?.currency ?? Currency.USD;
    final formatter =
        NumberFormat.currency(symbol: currency.name, decimalDigits: 2);
    final isMobile = MediaQuery.of(context).size.width < 600;

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: isMobile ? 20.0 : 32.0,
        right: isMobile ? 20.0 : 32.0,
        top: isMobile ? 20.0 : 32.0,
        bottom: isMobile ? 100.0 : 32.0, // Extra padding for bottom nav
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FadeInWidget(
            delay: const Duration(milliseconds: 50),
            child: _buildHeader(context, ref, period),
          ),
          const SizedBox(height: 24),
          FadeInWidget(
            delay: const Duration(milliseconds: 60),
            child: _buildWeeklyWrappedPrompt(context, ref),
          ),
          const SizedBox(height: 24),
          FadeInWidget(
            delay: const Duration(milliseconds: 100),
            child: _buildSummaryCards(ref, formatter),
          ),
          const SizedBox(height: 32),
          FadeInWidget(
            delay: const Duration(milliseconds: 150),
            child: _buildQuickStats(ref, formatter),
          ),
          const SizedBox(height: 32),
          FadeInWidget(
            delay: const Duration(milliseconds: 200),
            child: _buildRecentReceipts(context, ref, formatter),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, Period period) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dashboard',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            letterSpacing: -1.0,
            color: context.onSurfaceColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Track your expenses and manage receipts',
          style: TextStyle(
            fontSize: 16,
            color: context.onSurfaceMutedColor,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: context.borderColor.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: DropdownButton<Period>(
            value: period,
            underline: const SizedBox(),
            isDense: true,
            icon: Icon(Icons.keyboard_arrow_down_rounded,
                color: context.onSurfaceMutedColor),
            style: TextStyle(
              color: context.onSurfaceColor,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            dropdownColor: context.surfaceColor,
            selectedItemBuilder: (context) {
              return Period.values.map((p) {
                return Text(
                  p
                      .toString()
                      .split('.')
                      .last
                      .replaceAllMapped(
                        RegExp(r'([A-Z])'),
                        (m) => ' ${m.group(0)!}',
                      )
                      .trim(),
                  style: TextStyle(
                    color: context.onSurfaceColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                );
              }).toList();
            },
            items: Period.values.map((p) {
              return DropdownMenuItem(
                value: p,
                child: Text(
                  p
                      .toString()
                      .split('.')
                      .last
                      .replaceAllMapped(
                        RegExp(r'([A-Z])'),
                        (m) => ' ${m.group(0)!}',
                      )
                      .trim(),
                  style: TextStyle(
                    color: context.onSurfaceColor,
                  ),
                ),
              );
            }).toList(),
            onChanged: (p) {
              if (p != null) {
                ref.read(periodProvider.notifier).state = p;
              }
            },
          ),
        ),
      ],
    );
  }

  // --- Summary Cards Section ---
  Widget _buildSummaryCards(WidgetRef ref, NumberFormat formatter) {
    final statsAsync = ref.watch(dashboardStatsProvider);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: statsAsync.when(
        data: (stats) => LayoutBuilder(
          key: const ValueKey('stats_data'),
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;
            final crossAxisCount = isMobile ? 2 : 4;
            final spacing = isMobile ? 16.0 : 24.0;

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: isMobile ? 1.0 : 1.25,
                crossAxisSpacing: spacing,
                mainAxisSpacing: spacing,
              ),
              itemCount: 4,
              itemBuilder: (context, index) {
                switch (index) {
                  case 0:
                    return _SummaryCard(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'Total Spent',
                      value: formatter.format(stats.totalSpent),
                      subtitle: 'This Period',
                      trend: stats.trend,
                      change: stats.vsLastPeriodChange,
                    );
                  case 1:
                    return _SummaryCard(
                      icon: Icons.receipt_long,
                      title: 'Receipts',
                      value: stats.receiptsCount.toString(),
                      subtitle: 'Saved',
                    );
                  case 2:
                    return _SummaryCard(
                      icon: Icons.price_change,
                      title: 'Average',
                      value: formatter.format(stats.averagePerReceipt),
                      subtitle: 'Per Receipt',
                    );
                  case 3:
                    return _SummaryCard(
                      icon: Icons.store_outlined,
                      title: 'Top Store',
                      value: stats.topStore,
                      subtitle: 'Most visited',
                    );
                  default:
                    return const SizedBox.shrink();
                }
              },
            );
          },
        ),
        loading: () => LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;
            return _LoadingSkeleton(
              itemCount: 4,
              aspectRatio: isMobile ? 1.0 : 1.25,
            );
          },
        ),
        error: (e, s) => Builder(
          builder: (context) => Center(
            key: const ValueKey('stats_error'),
            child: Text(
              'Error loading stats: $e',
              style: TextStyle(color: context.errorColor),
            ),
          ),
        ),
      ),
    );
  }

  // --- Quick Stats Section ---
  Widget _buildQuickStats(WidgetRef ref, NumberFormat formatter) {
    final quickStatsAsync = ref.watch(quickStatsProvider);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: quickStatsAsync.when(
        data: (stats) => LayoutBuilder(
          key: const ValueKey('quick_stats_data'),
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;
            final crossAxisCount = isMobile ? 2 : 4;
            final spacing = isMobile ? 16.0 : 24.0;

            return GridView.count(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: spacing,
              crossAxisSpacing: spacing,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: isMobile ? 1.5 : 2.0,
              children: [
                _QuickStatBox(
                    title: 'Highest Expense',
                    value: formatter.format(stats.highestExpense)),
                _QuickStatBox(
                    title: 'Lowest Expense',
                    value: formatter.format(stats.lowestExpense)),
                _QuickStatBox(
                    title: 'Days with Expenses',
                    value: stats.daysWithExpenses.toString()),
                _QuickStatBox(
                    title: 'Total Items', value: stats.totalItems.toString()),
              ],
            );
          },
        ),
        loading: () => LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 600;
            return _LoadingSkeleton(
              itemCount: 4,
              aspectRatio: isMobile ? 1.5 : 2.0,
            );
          },
        ),
        error: (e, s) => Builder(
          builder: (context) => Center(
            key: const ValueKey('quick_stats_error'),
            child: Text(
              'Error loading quick stats: $e',
              style: TextStyle(color: context.errorColor),
            ),
          ),
        ),
      ),
    );
  }

  // --- Recent Receipts Table Section ---
  Widget _buildRecentReceipts(
      BuildContext context, WidgetRef ref, NumberFormat formatter) {
    final receiptsAsync = ref.watch(recentReceiptsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Receipts',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.5,
            height: 1.3,
            color: context.onSurfaceColor,
          ),
        ),
        const SizedBox(height: 16),
        receiptsAsync.when(
          data: (receipts) => receipts.isEmpty
              ? Center(
                  child: Text(
                    'No recent receipts.',
                    style: TextStyle(color: context.onSurfaceMutedColor),
                  ),
                )
              : _ReceiptsDataTable(receipts: receipts, formatter: formatter),
          loading: () => const _LoadingSkeletonTable(),
          error: (e, s) => Center(
            child: Text(
              'Error loading receipts: $e',
              style: TextStyle(color: context.errorColor),
            ),
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Component Widgets
// -----------------------------------------------------------------------------

class _SummaryCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final String trend;
  final double change;

  const _SummaryCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    this.trend = 'flat',
    this.change = 0.0,
  });

  @override
  State<_SummaryCard> createState() => _SummaryCardState();
}

class _SummaryCardState extends State<_SummaryCard>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trendIcon = widget.trend == 'up'
        ? Icons.arrow_upward
        : (widget.trend == 'down' ? Icons.arrow_downward : Icons.remove);
    final trendColor = widget.trend == 'up'
        ? Colors.green
        : (widget.trend == 'down' 
            ? Colors.red 
            : Theme.of(context).brightness == Brightness.dark 
                ? Colors.white70 
                : Colors.black54);

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Card(
        margin: const EdgeInsets.all(4),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTapDown: (_) {
              setState(() => _isPressed = true);
              _scaleController.forward();
            },
            onTapUp: (_) {
              setState(() => _isPressed = false);
              _scaleController.reverse();
            },
            onTapCancel: () {
              setState(() => _isPressed = false);
              _scaleController.reverse();
            },
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(widget.icon, color: context.primaryColor, size: 28),
                  const SizedBox(height: 10),
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.onSurfaceMutedColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          widget.value,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: context.onSurfaceColor,
                            height: 1.2,
                            letterSpacing: -0.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(trendIcon, color: trendColor, size: 12),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          widget.trend == 'flat'
                              ? widget.subtitle
                              : '${widget.change.toStringAsFixed(1)}% vs last period',
                          style: TextStyle(
                            fontSize: 11,
                            color: trendColor,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickStatBox extends StatefulWidget {
  final String title;
  final String value;

  const _QuickStatBox({required this.title, required this.value});

  @override
  State<_QuickStatBox> createState() => _QuickStatBoxState();
}

class _QuickStatBoxState extends State<_QuickStatBox>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _controller.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _controller.reverse();
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: context.borderColor.withOpacity(0.5),
              width: 1,
            ),
            boxShadow: _isHovered
                ? [
                    BoxShadow(
                      color: context.primaryColor.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                      spreadRadius: 0,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withOpacity(
                        Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.05,
                      ),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                      spreadRadius: 0,
                    ),
                  ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.title,
                  style: TextStyle(
                    fontSize: 12,
                    color: context.onSurfaceMutedColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    widget.value,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: context.onSurfaceColor,
                      height: 1.1,
                      letterSpacing: -0.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReceiptsDataTable extends StatelessWidget {
  final List<ReceiptSummaryModel> receipts;
  final NumberFormat formatter;

  const _ReceiptsDataTable({required this.receipts, required this.formatter});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: context.borderColor.withOpacity(0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.05,
            ),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
          columns: [
            DataColumn(
              label: Text(
                'Date',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0,
                  color: context.onSurfaceColor,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Store',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0,
                  color: context.onSurfaceColor,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Items Count',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0,
                  color: context.onSurfaceColor,
                ),
              ),
            ),
            DataColumn(
              label: Text(
                'Amount',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0,
                  color: context.onSurfaceColor,
                ),
                textAlign: TextAlign.right,
              ),
            ),
            DataColumn(
              label: Text(
                'Action',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0,
                  color: context.onSurfaceColor,
                ),
              ),
            ),
          ],
          rows: receipts.map((receipt) {
            return DataRow(
              cells: [
                DataCell(
                  Text(
                    DateFormat.yMd().format(receipt.savedAt),
                    style: TextStyle(color: context.onSurfaceColor),
                  ),
                ),
                DataCell(
                  Text(
                    receipt.store,
                    style: TextStyle(color: context.onSurfaceColor),
                  ),
                ),
                DataCell(
                  Text(
                    receipt.itemCount.toString(),
                    style: TextStyle(color: context.onSurfaceColor),
                  ),
                ),
                DataCell(
                  Align(
                    alignment: Alignment.centerRight,
                    child: Text(
                      formatter.format(receipt.total),
                      style: TextStyle(color: context.onSurfaceColor),
                    ),
                  ),
                ),
                DataCell(
                  ElevatedButton(
                    onPressed: () {
                      // Show Receipt Details Modal
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) =>
                            ReceiptDetailsModal(receiptId: receipt.id),
                      );
                    },
                    child: const Text('View'),
                  ),
                ),
              ],
            );
          }).toList(),
          ),
        ),
      ),
    );
  }
}

// --- Loading Skeleton for UX ---
class _LoadingSkeleton extends StatelessWidget {
  final int itemCount;
  final double aspectRatio;

  const _LoadingSkeleton({required this.itemCount, required this.aspectRatio});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final crossAxisCount = isMobile ? 2 : 4;
    final spacing = isMobile ? 16.0 : 24.0;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: aspectRatio,
        crossAxisSpacing: spacing,
        mainAxisSpacing: spacing,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) => ShimmerLoading(
        child: Card(
          color: context.surfaceColor,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonCard(
                    width: 30,
                    height: 30,
                    borderRadius: BorderRadius.circular(4)),
                const SizedBox(height: 12),
                const SkeletonText(width: 80, height: 12),
                const Spacer(),
                const SkeletonText(width: 120, height: 20),
                const SizedBox(height: 8),
                const SkeletonText(width: 60, height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildWeeklyWrappedPrompt(BuildContext context, WidgetRef ref) {
    // Check if it's been a week since last view
    final receiptsAsync = ref.watch(receiptsStoreProvider);
    final receipts = receiptsAsync.valueOrNull ?? [];
    
    if (receipts.isEmpty) {
      return const SizedBox.shrink();
    }
    
    // Get last week's start date
    final now = DateTime.now();
    final lastWeekStart = _getWeekStart(now.subtract(const Duration(days: 7)));
    final thisWeekStart = _getWeekStart(now);
    
    // Check if we have receipts from last week
    final lastWeekReceipts = receipts.where((r) {
      final receiptDate = DateTime(r.date.year, r.date.month, r.date.day);
      return receiptDate.isAfter(lastWeekStart.subtract(const Duration(days: 1))) &&
             receiptDate.isBefore(thisWeekStart);
    }).toList();
    
    if (lastWeekReceipts.isEmpty) {
      return const SizedBox.shrink();
    }
    
    // Check if user has viewed wrapped this week using a provider
    return ref.watch(shouldShowWrappedPromptProvider).when(
      data: (shouldShow) {
        if (!shouldShow) {
          return const SizedBox.shrink();
        }
        
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                context.primaryColor,
                context.primaryColor.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: context.primaryColor.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => context.go('/wrapped?weekStart=${lastWeekStart.toIso8601String()}'),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.celebration,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Your Week Wrapped is Ready! 🎵',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'See how you spent last week',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
  
  DateTime _getWeekStart(DateTime date) {
    final weekday = date.weekday;
    return date.subtract(Duration(days: weekday - 1));
  }
}

class _LoadingSkeletonTable extends StatelessWidget {
  const _LoadingSkeletonTable();
  // Simplified table skeleton for brevity
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: List.generate(
            5,
            (index) => Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 80,
                        height: 10,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white10
                            : Colors.black12,
                      ),
                      Container(
                        width: 120,
                        height: 10,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white10
                            : Colors.black12,
                      ),
                      Container(
                        width: 60,
                        height: 10,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white10
                            : Colors.black12,
                      ),
                      Container(
                        width: 50,
                        height: 10,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white10
                            : Colors.black12,
                      ),
                    ],
                  ),
                )),
      ),
    );
  }
}
