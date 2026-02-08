import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hisabi/features/receipts/providers/receipts_store.dart';
import 'package:hisabi/features/receipts/providers/receipt_filter_provider.dart';
import 'package:hisabi/features/receipts/presentation/widgets/receipt_details_modal.dart';
import 'package:hisabi/features/settings/providers/settings_provider.dart';
import 'package:hisabi/core/models/category_model.dart';

class SavedReceiptsScreen extends ConsumerStatefulWidget {
  const SavedReceiptsScreen({super.key});

  @override
  ConsumerState<SavedReceiptsScreen> createState() => _SavedReceiptsScreenState();
}

class _SavedReceiptsScreenState extends ConsumerState<SavedReceiptsScreen> {
  final _searchController = TextEditingController();
  bool _showSearch = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredReceiptsAsync = ref.watch(filteredReceiptsProvider);
    final filters = ref.watch(receiptFiltersProvider);
    final settingsAsync = ref.watch(settingsProvider);
    final currency = settingsAsync.valueOrNull?.currency ?? Currency.USD;
    final formatter = NumberFormat.currency(symbol: currency.name, decimalDigits: 2);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(receiptsStoreProvider.notifier).refresh();
        },
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            SliverAppBar.large(
              centerTitle: false,
              title: _showSearch
                  ? TextField(
                      controller: _searchController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'Search receipts...',
                        border: InputBorder.none,
                      ),
                      onChanged: (value) {
                        ref.read(receiptFiltersProvider.notifier).state = 
                          filters.copyWith(
                            searchQuery: value.isEmpty ? null : value,
                            clearSearchQuery: value.isEmpty,
                          );
                      },
                    )
                  : const Text('Saved Receipts'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh_rounded),
                  onPressed: () async {
                    await ref.read(receiptsStoreProvider.notifier).refresh();
                  },
                ),
                IconButton(
                  icon: Icon(_showSearch ? Icons.close : Icons.search_rounded),
                  onPressed: () {
                    setState(() {
                      _showSearch = !_showSearch;
                      if (!_showSearch) {
                        _searchController.clear();
                        ref.read(receiptFiltersProvider.notifier).state = 
                          filters.copyWith(clearSearchQuery: true);
                      }
                    });
                  },
                ),
                IconButton(
                  icon: Icon(
                    Icons.filter_list_rounded,
                    color: filters.hasFilters ? Theme.of(context).colorScheme.primary : null,
                  ),
                  onPressed: () => _showFilterModal(context, ref, filters),
                ),
                const SizedBox(width: 8),
              ],
            ),
          if (filters.hasFilters)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (filters.searchQuery != null && filters.searchQuery!.isNotEmpty)
                      Chip(
                        label: Text('Search: ${filters.searchQuery}'),
                        onDeleted: () {
                          ref.read(receiptFiltersProvider.notifier).state = 
                            filters.copyWith(clearSearchQuery: true);
                          _searchController.clear();
                        },
                      ),
                    if (filters.categoryFilter != null)
                      Chip(
                        label: Text('Category: ${CategoryInfo.getInfo(filters.categoryFilter!).name}'),
                        onDeleted: () {
                          ref.read(receiptFiltersProvider.notifier).state = 
                            filters.copyWith(clearCategoryFilter: true);
                        },
                      ),
                    if (filters.startDate != null || filters.endDate != null)
                      Chip(
                        label: Text('Date Range'),
                        onDeleted: () {
                          ref.read(receiptFiltersProvider.notifier).state = 
                            filters.copyWith(clearStartDate: true, clearEndDate: true);
                        },
                      ),
                    if (filters.minAmount != null || filters.maxAmount != null)
                      Chip(
                        label: Text('Amount Range'),
                        onDeleted: () {
                          ref.read(receiptFiltersProvider.notifier).state = 
                            filters.copyWith(clearMinAmount: true, clearMaxAmount: true);
                        },
                      ),
                    if (filters.storeFilter != null && filters.storeFilter!.isNotEmpty)
                      Chip(
                        label: Text('Store: ${filters.storeFilter}'),
                        onDeleted: () {
                          ref.read(receiptFiltersProvider.notifier).state = 
                            filters.copyWith(clearStoreFilter: true);
                        },
                      ),
                  ],
                ),
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
            sliver: filteredReceiptsAsync.when(
              data: (receipts) => receipts.isEmpty
                  ? const SliverFillRemaining(child: _EmptyState())
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final r = receipts[receipts.length - 1 - index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Card(
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                leading: Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(Icons.shopping_bag_outlined, color: Theme.of(context).colorScheme.primary),
                                ),
                                title: Text(
                                  r.store, 
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  DateFormat.yMMMd().format(r.date),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (r.isSplit)
                                      Padding(
                                        padding: const EdgeInsets.only(right: 8),
                                        child: Icon(
                                          Icons.call_split,
                                          size: 16,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    Text(
                                      formatter.format(r.total),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 16,
                                        color: Theme.of(context).colorScheme.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () => showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (_) => ReceiptDetailsModal(receiptId: r.id),
                                ),
                              ),
                            ).animate().fadeIn(delay: Duration(milliseconds: 50 * index)).slideX(begin: 0.1),
                          );
                        },
                        childCount: receipts.length,
                      ),
                    ),
              loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
              error: (error, stack) => SliverFillRemaining(child: Center(child: Text('Error loading receipts'))),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
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

    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
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
                value: selectedCategory,
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
                          Text(info.emoji),
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
  const _EmptyState();

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
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.receipt_long_outlined, size: 84, color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
            ),
            const SizedBox(height: 24),
            Text(
              'No receipts saved yet',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 15),
            Text(
              'Start tracking your expenses by adding your first receipt',
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
