import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hisabi/features/dashboard/providers/dashboard_provider.dart';
import 'package:hisabi/features/dashboard/providers/wrapped_prompt_provider.dart';
import 'package:hisabi/features/dashboard/presentation/widgets/budget_card.dart';
import 'package:hisabi/features/receipts/presentation/widgets/receipt_details_modal.dart';
import 'package:hisabi/features/settings/providers/settings_provider.dart';
import 'package:hisabi/features/financial_profile/providers/financial_profile_provider.dart';
import 'package:hisabi/core/models/receipt_summary_model.dart';

class DashboardNotification {
  final String title;
  final String message;
  final DateTime date;
  final bool isImportant;
  final VoidCallback? onTap;

  DashboardNotification({
    required this.title,
    required this.message,
    required this.date,
    this.isImportant = false,
    this.onTap,
  });
}

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(widgetUpdateProvider);
    final period = ref.watch(periodProvider);
    final settingsAsync = ref.watch(settingsProvider);
    final currency = settingsAsync.valueOrNull?.currency ?? Currency.USD;
    final formatter =
        NumberFormat.currency(symbol: currency.name, decimalDigits: 2);
    final isMobile = MediaQuery.of(context).size.width < 600;
    final theme = Theme.of(context);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardStatsProvider);
          ref.invalidate(recentReceiptsProvider);
        },
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            SliverAppBar.large(
              title: const Text('Dashboard'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () {
                    final statsAsync = ref.read(dashboardStatsProvider);
                    final stats = statsAsync.maybeWhen(
                      data: (value) => value,
                      orElse: () => null,
                    );

                    final shouldShowWrapped =
                        ref.read(shouldShowWrappedPromptProvider).maybeWhen(
                              data: (value) => value,
                              orElse: () => false,
                            );

                    final List<DashboardNotification> notifications = [];

                    if (shouldShowWrapped && stats != null) {
                      notifications.add(
                        DashboardNotification(
                          title: 'Weekly Wrapped is ready',
                          message:
                              'You spent ${formatter.format(stats.totalSpent)} this week. Tap to see your Wrapped.',
                          date: DateTime.now(),
                          isImportant: true,
                          onTap: () => context.go('/wrapped'),
                        ),
                      );
                    }

                    if (stats != null) {
                      notifications.add(
                        DashboardNotification(
                          title: 'Spending snapshot',
                          message:
                              'You have ${stats.receiptsCount} receipts this ${period.name.toLowerCase()} with an average of ${formatter.format(stats.averagePerReceipt)} per receipt.',
                          date:
                              DateTime.now().subtract(const Duration(hours: 2)),
                          isImportant: false,
                        ),
                      );

                      if (stats.topStore.isNotEmpty) {
                        notifications.add(
                          DashboardNotification(
                            title:
                                'Top store this ${period.name.toLowerCase()}',
                            message:
                                'You\'re spending the most at ${stats.topStore}. Keep an eye on how often you shop there.',
                            date: DateTime.now()
                                .subtract(const Duration(days: 1)),
                            isImportant: false,
                          ),
                        );
                      }
                    }

                    _showNotificationsSheet(context, notifications);
                  },
                ),
                const SizedBox(width: 8),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    _buildPeriodSelector(context, ref, period),
                    const SizedBox(height: 24),
                    _buildIncompleteProfileBanner(context, ref),
                    _buildWeeklyWrappedPrompt(context, ref),
                    const SizedBox(height: 24),
                    const BudgetCard(),
                    const SizedBox(height: 24),
                    _buildSummaryGrid(ref, formatter, isMobile, theme),
                    const SizedBox(height: 40),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSectionHeader(context, 'Recent Activity'),
                        TextButton(
                          onPressed: () => context.go('/saved-receipts'),
                          child: const Text('See All'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildRecentReceipts(context, ref, formatter),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncompleteProfileBanner(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(financialProfileProvider);

    return profileAsync.maybeWhen(
      data: (profile) {
        if (profile.isComplete) return const SizedBox.shrink();

        return Container(
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: Theme.of(context)
                .colorScheme
                .tertiaryContainer
                .withOpacity(0.5),
            border: Border.all(
              color: Theme.of(context).colorScheme.tertiary.withOpacity(0.2),
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => context.push('/financial-profile'),
              borderRadius: BorderRadius.circular(24),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .tertiary
                            .withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.account_balance_rounded,
                        color: Theme.of(context).colorScheme.tertiary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Setup Financial Profile',
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onTertiaryContainer,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Get smarter budget tips and limits',
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onTertiaryContainer
                                  .withOpacity(0.8),
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Theme.of(context).colorScheme.tertiary,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ).animate().fadeIn().slideY(begin: 0.1);
      },
      orElse: () => const SizedBox.shrink(),
    );
  }

  Widget _buildPeriodSelector(
      BuildContext context, WidgetRef ref, Period period) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: Period.values.map((p) {
            final isSelected = period == p;
            return GestureDetector(
              onTap: () => ref.read(periodProvider.notifier).state = p,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  p.name.toUpperCase(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: isSelected
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    ).animate().fadeIn().slideY(begin: 0.2);
  }

  Widget _buildSummaryGrid(
      WidgetRef ref, NumberFormat formatter, bool isMobile, ThemeData theme) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final highlightColor = theme.colorScheme.primary;

    return statsAsync.when(
      data: (stats) => GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: isMobile ? 2 : 4,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.1,
        children: [
          _SummaryCard(
            title: 'Total Spent',
            value: formatter.format(stats.totalSpent),
            icon: Icons.account_balance_wallet_rounded,
            color: highlightColor,
            delay: 100,
          ),
          _SummaryCard(
            title: 'Receipts',
            value: stats.receiptsCount.toString(),
            icon: Icons.receipt_long_rounded,
            color: highlightColor,
            delay: 200,
          ),
          _SummaryCard(
            title: 'Average',
            value: formatter.format(stats.averagePerReceipt),
            icon: Icons.analytics_rounded,
            color: highlightColor,
            delay: 300,
          ),
          _SummaryCard(
            title: 'Top Store',
            value: stats.topStore,
            icon: Icons.store_rounded,
            color: highlightColor,
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
            letterSpacing: -0.5,
          ),
    ).animate().fadeIn().slideX();
  }

  Widget _buildRecentReceipts(
      BuildContext context, WidgetRef ref, NumberFormat formatter) {
    final receiptsAsync = ref.watch(recentReceiptsProvider);

    return receiptsAsync.when(
      data: (receipts) => receipts.isEmpty
          ? _buildEmptyState(context)
          : ListView.separated(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: receipts.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final receipt = receipts[index];
                return _ReceiptListItem(receipt: receipt, formatter: formatter);
              },
            ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Text('Error: $e'),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_outlined,
                size: 80, color: Theme.of(context).colorScheme.outlineVariant),
            const SizedBox(height: 16),
            Text(
              'No recent activity',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyWrappedPrompt(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    return ref.watch(shouldShowWrappedPromptProvider).when(
          data: (shouldShow) => shouldShow
              ? Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: LinearGradient(
                      colors: [
                        colorScheme.primary,
                        colorScheme.secondary,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.primary.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => context.go('/wrapped'),
                      borderRadius: BorderRadius.circular(24),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.auto_awesome_rounded,
                                  color: Colors.white, size: 28),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Week Wrapped!',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 20),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Your spending story is ready',
                                    style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded,
                                color: Colors.white, size: 28),
                          ],
                        ),
                      ),
                    ),
                  ),
                ).animate().shake(delay: 800.ms).shimmer(duration: 3.seconds)
              : const SizedBox.shrink(),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        );
  }
}

void _showNotificationsSheet(
  BuildContext context,
  List<DashboardNotification> notifications,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (_, scrollController) {
          if (notifications.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Notifications',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'You are all caught up. We will let you know when there is something new about your spending.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.only(
              top: 8,
              left: 16,
              right: 16,
              bottom: 16,
            ),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade400,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      'Notifications',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Spacer(),
                    Text(
                      '${notifications.length}',
                      style: Theme.of(context)
                          .textTheme
                          .labelMedium
                          ?.copyWith(color: Colors.grey.shade600),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    itemCount: notifications.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, index) {
                      final n = notifications[index];

                      Widget tile = Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: n.isImportant
                              ? Theme.of(context)
                                  .colorScheme
                                  .errorContainer
                                  .withOpacity(0.12)
                              : Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: n.isImportant
                                ? Theme.of(context)
                                    .colorScheme
                                    .error
                                    .withOpacity(0.4)
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              n.isImportant
                                  ? Icons.warning_amber_rounded
                                  : Icons.insights_rounded,
                              color: n.isImportant
                                  ? Theme.of(context).colorScheme.error
                                  : Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    n.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleSmall
                                        ?.copyWith(
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    n.message,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Colors.grey.shade700,
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatNotificationDate(n.date),
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: Colors.grey.shade500,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );

                      if (n.onTap != null) {
                        tile = GestureDetector(
                          onTap: () {
                            Navigator.of(context).pop();
                            n.onTap!();
                          },
                          child: tile,
                        );
                      }

                      return tile;
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

String _formatNotificationDate(DateTime date) {
  final now = DateTime.now();
  final diff = now.difference(date);

  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) return '${diff.inHours} h ago';
  if (diff.inDays < 7) return '${diff.inDays} d ago';
  return '${date.day}/${date.month}/${date.year}';
}

class _ReceiptListItem extends StatelessWidget {
  final ReceiptSummaryModel receipt;
  final NumberFormat formatter;

  const _ReceiptListItem({required this.receipt, required this.formatter});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color:
                Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.shopping_bag_outlined,
              color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(
          receipt.store,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          DateFormat.yMMMd().format(receipt.savedAt),
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 13,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: Text(
          formatter.format(receipt.total),
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 16,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        onTap: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => ReceiptDetailsModal(receiptId: receipt.id),
        ),
      ),
    ).animate().fadeIn().slideX(begin: 0.1);
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
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  child: Text(
                    value,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: delay))
        .scale(begin: const Offset(0.95, 0.95));
  }
}
