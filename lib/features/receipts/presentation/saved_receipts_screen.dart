import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hisabi/core/models/receipt_model.dart';
import 'package:hisabi/features/receipts/providers/receipts_store.dart';
import 'package:hisabi/features/receipts/providers/receipt_filter_provider.dart';
import 'package:hisabi/features/receipts/presentation/widgets/receipt_details_modal.dart';
import 'package:hisabi/features/settings/providers/settings_provider.dart';
import 'package:hisabi/core/models/category_model.dart';
import 'package:hisabi/core/widgets/app_bottom_sheet.dart';
import 'package:hisabi/core/widgets/app_snackbar.dart';

class SavedReceiptsScreen extends ConsumerStatefulWidget {
  const SavedReceiptsScreen({super.key});

  @override
  ConsumerState<SavedReceiptsScreen> createState() => _SavedReceiptsScreenState();
}

class _SavedReceiptsScreenState extends ConsumerState<SavedReceiptsScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredReceiptsAsync = ref.watch(filteredReceiptsProvider);
    final filters = ref.watch(receiptFiltersProvider);
    final allReceiptsAsync = ref.watch(receiptsStoreProvider);
    final settingsAsync = ref.watch(settingsProvider);
    final currency = settingsAsync.valueOrNull?.currency ?? Currency.USD;
    final formatter =
        NumberFormat.currency(symbol: currency.name, decimalDigits: 2);

    if (_searchController.text != (filters.searchQuery ?? '')) {
      _searchController.value = TextEditingValue(
        text: filters.searchQuery ?? '',
        selection: TextSelection.collapsed(
          offset: (filters.searchQuery ?? '').length,
        ),
      );
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(receiptsStoreProvider.notifier).refresh();
        },
        child: CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverAppBar.large(
              title: const Text('Saved Receipts'),
              centerTitle: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: () async {
                    await ref.read(receiptsStoreProvider.notifier).refresh();
                    if (context.mounted) {
                      showAppSnackBar(
                        context,
                        message: 'Receipts refreshed',
                        icon: Icons.check_circle_rounded,
                      );
                    }
                  },
                ),
                IconButton(
                  icon: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(
                        Icons.filter_list_rounded,
                        color: filters.hasFilters
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                      if (_activeFiltersCount(filters) > 0)
                        Positioned(
                          right: -6,
                          top: -6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '${_activeFiltersCount(filters)}',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  onPressed: () => _showFilterModal(context, ref, filters),
                ),
                const SizedBox(width: 8),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .outlineVariant
                              .withOpacity(0.25),
                        ),
                      ),
                      child: Column(
                        children: [
                          TextField(
                            controller: _searchController,
                            textInputAction: TextInputAction.search,
                            decoration: InputDecoration(
                              hintText: 'Search by store, name, or item',
                              prefixIcon: const Icon(Icons.search_rounded),
                              suffixIcon: (filters.searchQuery?.isNotEmpty ?? false)
                                  ? IconButton(
                                      icon: const Icon(Icons.close_rounded),
                                      onPressed: () {
                                        _searchController.clear();
                                        ref
                                            .read(receiptFiltersProvider.notifier)
                                            .state = filters.copyWith(
                                          clearSearchQuery: true,
                                        );
                                      },
                                    )
                                  : null,
                              filled: true,
                              fillColor: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest
                                  .withOpacity(0.35),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: BorderSide.none,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                            ),
                            onChanged: (value) {
                              ref.read(receiptFiltersProvider.notifier).state =
                                  filters.copyWith(
                                searchQuery: value.isEmpty ? null : value,
                                clearSearchQuery: value.isEmpty,
                              );
                            },
                          ),
                          const SizedBox(height: 12),
                          filteredReceiptsAsync.when(
                            data: (receipts) {
                              final allCount =
                                  allReceiptsAsync.valueOrNull?.length ?? 0;
                              final visibleTotal = receipts.fold<double>(
                                0,
                                (sum, r) => sum + r.total,
                              );
                              return _buildSummaryRow(
                                context,
                                formatter: formatter,
                                visibleCount: receipts.length,
                                allCount: allCount,
                                visibleTotal: visibleTotal,
                              );
                            },
                            loading: () => const SizedBox.shrink(),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                    if (filters.hasFilters) ...[
                      const SizedBox(height: 12),
                      _buildActiveFilters(context, ref, filters),
                    ],
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              sliver: filteredReceiptsAsync.when(
                data: (receipts) => receipts.isEmpty
                    ? SliverFillRemaining(
                        child: _EmptyState(hasFilters: filters.hasFilters),
                      )
                    : SliverList(
                        delegate: SliverChildListDelegate(
                          _buildGroupedReceiptWidgets(
                            context,
                            receipts: receipts,
                            formatter: formatter,
                          ),
                        ),
                      ),
                loading: () => const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, stack) => const SliverFillRemaining(
                  child: Center(child: Text('Error loading receipts')),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildGroupedReceiptWidgets(
    BuildContext context, {
    required List<ReceiptModel> receipts,
    required NumberFormat formatter,
  }) {
    final sorted = [...receipts]..sort((a, b) => b.date.compareTo(a.date));
    final sections = <_ReceiptMonthSection>[];
    for (final receipt in sorted) {
      final monthKey = DateTime(receipt.date.year, receipt.date.month);
      if (sections.isEmpty || sections.last.month != monthKey) {
        sections.add(_ReceiptMonthSection(month: monthKey, receipts: [receipt]));
      } else {
        sections.last.receipts.add(receipt);
      }
    }

    final widgets = <Widget>[];
    var animationIndex = 0;
    for (final section in sections) {
      widgets.add(
        Padding(
          padding: EdgeInsets.only(
            top: widgets.isEmpty ? 0 : 8,
            bottom: 10,
          ),
          child: _MonthHeader(month: section.month),
        ),
      );
      for (final receipt in section.receipts) {
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ReceiptCard(
              receipt: receipt,
              formatter: formatter,
              onTap: () => showAppBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                builder: (_) => ReceiptDetailsModal(receiptId: receipt.id),
              ),
            )
                .animate()
                .fadeIn(delay: Duration(milliseconds: 28 * animationIndex))
                .slideX(begin: 0.05),
          ),
        );
        animationIndex++;
      }
    }
    return widgets;
  }

  Widget _buildSummaryRow(
    BuildContext context, {
    required NumberFormat formatter,
    required int visibleCount,
    required int allCount,
    required double visibleTotal,
  }) {
    final cs = Theme.of(context).colorScheme;
    final subtitle = visibleCount == allCount
        ? 'All receipts'
        : 'Filtered from $allCount receipts';
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.outlineVariant.withOpacity(0.25)),
              boxShadow: [
                BoxShadow(
                  color: cs.shadow.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$visibleCount receipts',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.primaryContainer.withOpacity(0.4),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: cs.shadow.withOpacity(0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formatter.format(visibleTotal),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: cs.onPrimaryContainer,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Visible spend',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onPrimaryContainer.withOpacity(0.8),
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveFilters(
      BuildContext context, WidgetRef ref, ReceiptFilters filters) {
    final formatter = NumberFormat.compactCurrency(
      symbol: '',
      decimalDigits: 0,
    );
    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          if (filters.searchQuery != null && filters.searchQuery!.isNotEmpty)
            InputChip(
              label: Text('Search: ${filters.searchQuery}'),
              onDeleted: () {
                _searchController.clear();
                ref.read(receiptFiltersProvider.notifier).state =
                    filters.copyWith(clearSearchQuery: true);
              },
            ),
          if (filters.categoryFilter != null)
            InputChip(
              label:
                  Text('Category: ${CategoryInfo.getInfo(filters.categoryFilter!).name}'),
              onDeleted: () {
                ref.read(receiptFiltersProvider.notifier).state =
                    filters.copyWith(clearCategoryFilter: true);
              },
            ),
          if (filters.startDate != null || filters.endDate != null)
            InputChip(
              label: Text(
                filters.startDate != null && filters.endDate != null
                    ? '${DateFormat.yMMMd().format(filters.startDate!)} - ${DateFormat.yMMMd().format(filters.endDate!)}'
                    : filters.startDate != null
                        ? 'From ${DateFormat.yMMMd().format(filters.startDate!)}'
                        : 'Until ${DateFormat.yMMMd().format(filters.endDate!)}',
              ),
              onDeleted: () {
                ref.read(receiptFiltersProvider.notifier).state = filters
                    .copyWith(clearStartDate: true, clearEndDate: true);
              },
            ),
          if (filters.minAmount != null || filters.maxAmount != null)
            InputChip(
              label: Text(
                filters.minAmount != null && filters.maxAmount != null
                    ? 'Amount: ${formatter.format(filters.minAmount)} - ${formatter.format(filters.maxAmount)}'
                    : filters.minAmount != null
                        ? 'Amount >= ${formatter.format(filters.minAmount)}'
                        : 'Amount <= ${formatter.format(filters.maxAmount)}',
              ),
              onDeleted: () {
                ref.read(receiptFiltersProvider.notifier).state =
                    filters.copyWith(clearMinAmount: true, clearMaxAmount: true);
              },
            ),
          if (filters.storeFilter != null && filters.storeFilter!.isNotEmpty)
            InputChip(
              label: Text('Store: ${filters.storeFilter}'),
              onDeleted: () {
                ref.read(receiptFiltersProvider.notifier).state =
                    filters.copyWith(clearStoreFilter: true);
              },
            ),
          ActionChip(
            avatar: const Icon(Icons.clear_all_rounded, size: 18),
            label: const Text('Clear all'),
            onPressed: () {
              _searchController.clear();
              ref.read(receiptFiltersProvider.notifier).state = ReceiptFilters();
            },
          ),
        ],
      ),
    );
  }

  int _activeFiltersCount(ReceiptFilters filters) {
    var count = 0;
    if (filters.searchQuery != null && filters.searchQuery!.isNotEmpty) count++;
    if (filters.categoryFilter != null) count++;
    if (filters.startDate != null || filters.endDate != null) count++;
    if (filters.minAmount != null || filters.maxAmount != null) count++;
    if (filters.storeFilter != null && filters.storeFilter!.isNotEmpty) count++;
    return count;
  }

  void _showFilterModal(BuildContext context, WidgetRef ref, ReceiptFilters currentFilters) {
    ExpenseCategory? selectedCategory = currentFilters.categoryFilter;
    DateTimeRange? dateRange = currentFilters.startDate != null && currentFilters.endDate != null
        ? DateTimeRange(start: currentFilters.startDate!, end: currentFilters.endDate!)
        : null;
    final minAmountController = TextEditingController(
      text: currentFilters.minAmount?.toStringAsFixed(2) ?? '',
    );
    final maxAmountController = TextEditingController(
      text: currentFilters.maxAmount?.toStringAsFixed(2) ?? '',
    );
    final storeController = TextEditingController(
      text: currentFilters.storeFilter ?? '',
    );

    showAppBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: StatefulBuilder(
        builder: (context, setState) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filter Receipts',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<ExpenseCategory?>(
                initialValue: selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<ExpenseCategory?>(
                    value: null,
                    child: Text('All Categories'),
                  ),
                  ...ExpenseCategory.values.map((category) {
                    final info = CategoryInfo.getInfo(category);
                    return DropdownMenuItem<ExpenseCategory?>(
                      value: category,
                      child: Row(
                        children: [
                          Icon(
                            info.icon,
                            size: 18,
                            color: CategoryInfo.themedColor(context, category),
                          ),
                          const SizedBox(width: 8),
                          Text(info.name),
                        ],
                      ),
                    );
                  }),
                ],
                onChanged: (value) {
                  setState(() => selectedCategory = value);
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: storeController,
                decoration: const InputDecoration(
                  labelText: 'Store Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: minAmountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Min Amount',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: maxAmountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Max Amount',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () async {
                  final range = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                    initialDateRange: dateRange,
                  );
                  if (range != null) {
                    setState(() => dateRange = range);
                  }
                },
                icon: const Icon(Icons.calendar_today),
                label: Text(dateRange == null
                    ? 'Select Date Range'
                    : '${DateFormat.yMMMd().format(dateRange!.start)} - ${DateFormat.yMMMd().format(dateRange!.end)}'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        ref.read(receiptFiltersProvider.notifier).state = ReceiptFilters();
                        Navigator.pop(context);
                      },
                      child: const Text('Clear All'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        ref.read(receiptFiltersProvider.notifier).state = ReceiptFilters(
                          categoryFilter: selectedCategory,
                          startDate: dateRange?.start,
                          endDate: dateRange?.end,
                          minAmount: double.tryParse(minAmountController.text),
                          maxAmount: double.tryParse(maxAmountController.text),
                          storeFilter: storeController.text.isEmpty ? null : storeController.text,
                        );
                        Navigator.pop(context);
                      },
                      child: const Text('Apply'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool hasFilters;
  const _EmptyState({required this.hasFilters});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLow,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.receipt_long_outlined, size: 84, color: Theme.of(context).colorScheme.outlineVariant),
            ),
            const SizedBox(height: 24),
            Text(
              hasFilters ? 'No matching receipts' : 'No receipts saved yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 15),
            Text(
              hasFilters
                  ? 'Try changing search or filters to find what you need.'
                  : 'Start tracking your expenses by adding your first receipt.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
                height: 1.5,
              ),
            ),
          ],
        ),
      ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9)),
    );
  }
}

class _ReceiptCard extends StatelessWidget {
  final ReceiptModel receipt;
  final NumberFormat formatter;
  final VoidCallback onTap;

  const _ReceiptCard({
    required this.receipt,
    required this.formatter,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final categoryInfo = receipt.primaryCategory != null
        ? CategoryInfo.getInfo(receipt.primaryCategory!)
        : CategoryInfo.getInfo(ExpenseCategory.other);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: cs.outlineVariant.withOpacity(0.25)),
            boxShadow: [
              BoxShadow(
                color: cs.shadow.withOpacity(0.035),
                blurRadius: 12,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: cs.primaryContainer.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      categoryInfo.icon,
                      size: 22,
                      color: CategoryInfo.themedColor(
                        context,
                        categoryInfo.category,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          receipt.store,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 3),
                        if (receipt.name.trim().isNotEmpty &&
                            receipt.name.trim().toLowerCase() !=
                                receipt.store.trim().toLowerCase())
                          Text(
                            receipt.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: cs.onSurfaceVariant.withOpacity(0.9),
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        const SizedBox(height: 3),
                        Text(
                          DateFormat.yMMMd().format(receipt.date),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: cs.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatter.format(receipt.total),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${receipt.items.length} ${receipt.items.length == 1 ? 'item' : 'items'}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: cs.onSurfaceVariant.withOpacity(0.8),
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: cs.secondaryContainer.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      categoryInfo.name,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: cs.onSecondaryContainer,
                          ),
                    ),
                  ),
                  const Spacer(),
                  if (receipt.isSplit)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: cs.tertiaryContainer.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.call_split_rounded,
                            size: 14,
                            color: cs.onTertiaryContainer,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Split bill',
                            style:
                                Theme.of(context).textTheme.labelSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: cs.onTertiaryContainer,
                                    ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MonthHeader extends StatelessWidget {
  final DateTime month;
  const _MonthHeader({required this.month});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Text(
          DateFormat.yMMMM().format(month),
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 1,
            color: cs.outlineVariant.withOpacity(0.45),
          ),
        ),
      ],
    );
  }
}

class _ReceiptMonthSection {
  final DateTime month;
  final List<ReceiptModel> receipts;

  _ReceiptMonthSection({
    required this.month,
    required this.receipts,
  });
}
