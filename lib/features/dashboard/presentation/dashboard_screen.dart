import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hisabi/features/dashboard/providers/dashboard_provider.dart';
import 'package:hisabi/features/dashboard/providers/wrapped_prompt_provider.dart';
import 'package:hisabi/features/receipts/presentation/widgets/receipt_details_modal.dart';
import 'package:hisabi/features/receipts/providers/receipts_store.dart';
import 'package:hisabi/features/settings/providers/settings_provider.dart';
import 'package:hisabi/core/models/receipt_summary_model.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(widgetUpdateProvider);
    final period = ref.watch(periodProvider);
    final settingsAsync = ref.watch(settingsProvider);
    final currency = settingsAsync.valueOrNull?.currency ?? Currency.USD;
    final formatter = NumberFormat.currency(symbol: currency.name, decimalDigits: 2);
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          const SliverAppBar.large(
            title: Text('Dashboard'),
            centerTitle: false,
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 1),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: SegmentedButton<Period>(
                        segments: Period.values.map((p) => ButtonSegment(
                          value: p,
                          label: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12.0),
                            child: Text(p.name.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
                          ),
                        )).toList(),
                        selected: {period},
                        onSelectionChanged: (value) => ref.read(periodProvider.notifier).state = value.first,
                        showSelectedIcon: false,
                        style: SegmentedButton.styleFrom(
                          side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5)),
                          backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
                          selectedBackgroundColor: Theme.of(context).colorScheme.primary,
                          selectedForegroundColor: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ).animate().fadeIn().slideY(begin: 0.2),
                  const SizedBox(height: 40),
                  _buildWeeklyWrappedPrompt(context, ref),
                  const SizedBox(height: 10), // Gap between wrapped and the 4 widgets below
                  _buildSummaryGrid(ref, formatter, isMobile),
                  const SizedBox(height: 1),
                  _buildSectionHeader(context, 'Recent Activity'),
                  const SizedBox(height: 2),
                  _buildRecentReceipts(context, ref, formatter),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryGrid(WidgetRef ref, NumberFormat formatter, bool isMobile) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    
    return statsAsync.when(
      data: (stats) => GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: isMobile ? 2 : 4,
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        childAspectRatio: 1.05,
        children: [
          _SummaryCard(
            title: 'Total Spent',
            value: formatter.format(stats.totalSpent),
            icon: Icons.account_balance_wallet,
            color: Colors.blue,
            delay: 100,
          ),
          _SummaryCard(
            title: 'Receipts',
            value: stats.receiptsCount.toString(),
            icon: Icons.receipt_long,
            color: Colors.orange,
            delay: 200,
          ),
          _SummaryCard(
            title: 'Average',
            value: formatter.format(stats.averagePerReceipt),
            icon: Icons.analytics,
            color: Colors.purple,
            delay: 300,
          ),
          _SummaryCard(
            title: 'Top Store',
            value: stats.topStore,
            icon: Icons.store,
            color: Colors.green,
            delay: 400,
          ),
        ],
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Text('Error: $e'),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w900,
        letterSpacing: -0.8,
        fontSize: 35,
      ),
    ).animate().fadeIn().slideX();
  }

  Widget _buildRecentReceipts(BuildContext context, WidgetRef ref, NumberFormat formatter) {
    final receiptsAsync = ref.watch(recentReceiptsProvider);

    return receiptsAsync.when(
      data: (receipts) => receipts.isEmpty 
        ? Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 80.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_outlined, size: 96, color: Theme.of(context).colorScheme.outlineVariant),
                  const SizedBox(height: 24),
                  Text(
                    'No receipts added yet', 
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          )
        : ListView.separated(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: receipts.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final receipt = receipts[index];
              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  leading: CircleAvatar(
                    radius: 26,
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.4),
                    child: Icon(Icons.shopping_bag, color: Theme.of(context).colorScheme.primary),
                  ),
                  title: Text(receipt.store, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  subtitle: Text(DateFormat.yMMMd().format(receipt.savedAt), style: const TextStyle(fontWeight: FontWeight.w600)),
                  trailing: Text(
                    formatter.format(receipt.total),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  onTap: () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => ReceiptDetailsModal(receiptId: receipt.id),
                  ),
                ),
              ).animate().fadeIn(delay: Duration(milliseconds: 100 * index)).slideX();
            },
          ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Text('Error: $e'),
    );
  }

  Widget _buildWeeklyWrappedPrompt(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    return ref.watch(shouldShowWrappedPromptProvider).when(
      data: (shouldShow) => shouldShow ? Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          gradient: LinearGradient(
            colors: [
              colorScheme.primary,
              colorScheme.secondary,
              colorScheme.tertiary,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.primary.withOpacity(0.4),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.go('/wrapped'),
            borderRadius: BorderRadius.circular(32),
            child: Padding(
              padding: const EdgeInsets.all(28.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.auto_awesome, color: Colors.white, size: 36),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Week Wrapped Ready!', 
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 24, letterSpacing: -0.5),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Check out your spending story', 
                          style: TextStyle(color: Colors.white.withOpacity(0.85), fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 24),
                ],
              ),
            ),
          ),
        ),
      ).animate().shake(delay: 800.ms).shimmer(duration: 3.seconds) : const SizedBox.shrink(),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final int delay;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 14),
            Text(title, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 6),
            FittedBox(
              child: Text(
                value,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.2,
                  fontSize: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: delay)).scale(begin: const Offset(0.9, 0.9));
  }
}
