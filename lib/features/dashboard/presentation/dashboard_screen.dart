import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:hisabi/core/constants/app_styles.dart';
import 'package:hisabi/core/constants/app_theme.dart';
import 'package:hisabi/core/widgets/fade_in_widget.dart';
import 'package:hisabi/core/widgets/shimmer_loading.dart';
import 'package:hisabi/features/dashboard/providers/dashboard_provider.dart';
import 'package:hisabi/features/receipts/presentation/widgets/receipt_details_modal.dart';
import 'package:hisabi/features/settings/providers/settings_provider.dart';
import 'package:hisabi/core/models/receipt_summary_model.dart';

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
          const SizedBox(height: 32),
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
        const Text(
          'Dashboard',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            letterSpacing: -1.0,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Track your expenses and manage receipts',
          style: TextStyle(
            fontSize: 16,
            color: AppColors.onSurfaceMuted,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 20),
        // Period Selector
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.border.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: DropdownButton<Period>(
          value: period,
            underline: const SizedBox(),
            isDense: true,
            icon: const Icon(Icons.keyboard_arrow_down_rounded,
                color: AppColors.onSurfaceMuted),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            dropdownColor: AppColors.surface,
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
        error: (e, s) => Center(
            key: const ValueKey('stats_error'),
            child: Text('Error loading stats: $e')),
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
        error: (e, s) => Center(
            key: const ValueKey('quick_stats_error'),
            child: Text('Error loading quick stats: $e')),
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
        const Text(
          'Recent Receipts',
          style: AppText.title,
        ),
        const SizedBox(height: 16),
        receiptsAsync.when(
          data: (receipts) => receipts.isEmpty 
              ? const Center(child: Text('No recent receipts.'))
              : _ReceiptsDataTable(receipts: receipts, formatter: formatter),
          loading: () => const _LoadingSkeletonTable(),
          error: (e, s) => Center(child: Text('Error loading receipts: $e')),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Component Widgets
// -----------------------------------------------------------------------------

class _SummaryCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final trendIcon = trend == 'up'
        ? Icons.arrow_upward
        : (trend == 'down' ? Icons.arrow_downward : Icons.remove);
    final trendColor = trend == 'up'
        ? Colors.green
        : (trend == 'down' ? Colors.red : Colors.white70);
    
    return Card(
      margin: const EdgeInsets.all(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primary, size: 28),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.onSurfaceMuted,
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
                    value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface,
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
                    trend == 'flat'
                        ? subtitle
                        : '${change.toStringAsFixed(1)}% vs last period',
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
    );
  }
}

class _QuickStatBox extends StatelessWidget {
  final String title;
  final String value;

  const _QuickStatBox({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.onSurfaceMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 10),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
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
    );
  }
}

class _ReceiptsDataTable extends StatelessWidget {
  final List<ReceiptSummaryModel> receipts;
  final NumberFormat formatter;

  const _ReceiptsDataTable({required this.receipts, required this.formatter});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: const [
            DataColumn(label: Text('Date', style: AppText.label)),
            DataColumn(label: Text('Store', style: AppText.label)),
            DataColumn(label: Text('Items Count', style: AppText.label)),
            DataColumn(
                label: Text('Amount',
                    style: AppText.label, textAlign: TextAlign.right)),
            DataColumn(label: Text('Action', style: AppText.label)),
          ],
          rows: receipts.map((receipt) {
            return DataRow(
              cells: [
                DataCell(Text(DateFormat.yMd().format(receipt.savedAt))),
                DataCell(Text(receipt.store)),
                DataCell(Text(receipt.itemCount.toString())),
                DataCell(Align(
                  alignment: Alignment.centerRight,
                  child: Text(formatter.format(receipt.total)),
                )),
                DataCell(ElevatedButton(
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
                )),
              ],
            );
          }).toList(),
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
          color: AppColors.surface,
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
              Container(width: 80, height: 10, color: Colors.white10),
              Container(width: 120, height: 10, color: Colors.white10),
              Container(width: 60, height: 10, color: Colors.white10),
              Container(width: 50, height: 10, color: Colors.white10),
            ],
          ),
        )),
      ),
    );
  }
}
