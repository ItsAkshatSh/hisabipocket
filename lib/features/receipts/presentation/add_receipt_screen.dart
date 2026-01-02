import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:hisabi/core/models/receipt_model.dart';
import 'package:hisabi/core/constants/app_theme.dart';
import 'package:hisabi/core/widgets/fade_in_widget.dart';
import 'package:hisabi/features/receipts/providers/receipt_provider.dart';
import 'package:hisabi/features/settings/providers/settings_provider.dart';

class AddReceiptScreen extends ConsumerStatefulWidget {
  const AddReceiptScreen({super.key});

  @override
  ConsumerState<AddReceiptScreen> createState() => _AddReceiptScreenState();
}

class _AddReceiptScreenState extends ConsumerState<AddReceiptScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Save Receipt Flow Handler
  // ---------------------------------------------------------------------------
  void _startSaveReceiptFlow(ReceiptModel receipt) {
    showDialog(
      context: context,
      builder: (context) => _SaveReceiptModal(receipt: receipt),
    ).then((saved) {
      // Optionally refresh Dashboard/Saved Receipts lists here
      if (saved == true) {
        // Show success toast
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Receipt saved successfully!',
                    style: TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.surface,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
        ref.read(receiptEntryProvider.notifier).clearResult();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ReceiptEntryState>(receiptEntryProvider, (previous, next) {
      if (next.analysisError != null && previous?.analysisError == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Analysis Failed: ${next.analysisError}')),
              ],
            ),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    });

    final entryState = ref.watch(receiptEntryProvider);
    final isAnalysisComplete = entryState.analyzedReceipt != null;

    final isMobile = MediaQuery.of(context).size.width < 600;

    return Stack(
      children: [
        SingleChildScrollView(
          padding: EdgeInsets.only(
            left: isMobile ? 20.0 : 32.0,
            right: isMobile ? 20.0 : 32.0,
            top: isMobile ? 20.0 : 32.0,
            bottom: isMobile ? 120.0 : 32.0, // Extra space for FAB
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeInWidget(
                delay: const Duration(milliseconds: 50),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'New Receipt Entry',
                        style: Theme.of(context).textTheme.displayMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.onSurface,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const FadeInWidget(
                delay: Duration(milliseconds: 100),
                child: Text(
                  'Upload a receipt image or enter details manually',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.onSurfaceMuted,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              const SizedBox(height: 32),

          // Show Results Section if analysis is complete
          if (isAnalysisComplete)
            FadeInWidget(
              child: _ResultsSection(
                receipt: entryState.analyzedReceipt!,
                onSave: _startSaveReceiptFlow,
                onClear: ref.read(receiptEntryProvider.notifier).clearResult,
              ),
            )
          else
            _buildEntryTabs(context, entryState.isAnalyzing),
            ],
          ),
        ),
        // Quick Add Floating Button
        Positioned(
          bottom: isMobile ? 80 : 24,
          right: isMobile ? 20 : 32,
          child: _QuickAddButton(),
        ),
      ],
    );
  }

  Widget _buildEntryTabs(BuildContext context, bool isAnalyzing) {
    return FadeInWidget(
      delay: const Duration(milliseconds: 150),
      child: Column(
        children: [
          // Modern Tab Bar
          Container(
            constraints: const BoxConstraints(minHeight: 64),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.border,
                width: 1,
              ),
            ),
            padding: const EdgeInsets.all(4),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: AppColors.primary,
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: AppColors.onSurfaceMuted,
              labelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.0,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 1.0,
              ),
              labelPadding: EdgeInsets.zero,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              tabs: const [
                Tab(
                  height: 56,
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cloud_upload_outlined, size: 16),
                        SizedBox(height: 3),
                        Text(
                          'Upload Receipt',
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
                Tab(
                  height: 56,
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.edit_outlined, size: 16),
                        SizedBox(height: 3),
                        Text(
                          'Manual Entry',
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Tab Content
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.65,
            child: TabBarView(
              controller: _tabController,
              children: [
                _UploadReceiptTab(isAnalyzing: isAnalyzing),
                _ManualEntryTab(onSave: (r) => _startSaveReceiptFlow(r)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Tab 1: Upload Receipt
// -----------------------------------------------------------------------------
class _UploadReceiptTab extends ConsumerWidget {
  final bool isAnalyzing;
  const _UploadReceiptTab({required this.isAnalyzing});

  void _handleImageUpload(WidgetRef ref) async {
    // In a real app, use image_picker or file_picker package
    // For MVP, simulate a file selection

    // final imageFile = await pickImage();
    // if (imageFile != null) {
    //   ref.read(receiptEntryProvider.notifier).analyzeImage(imageFile);
    // }

    // Simulation:
    // Passing a dummy File object for simulation purposes
    ref.read(receiptEntryProvider.notifier).analyzeImage(File('dummy.jpg'));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Enhanced Drag-and-Drop Area
        _UploadArea(
          onTap: () => _handleImageUpload(ref),
          isAnalyzing: isAnalyzing,
        ),
        const SizedBox(height: 40),
        if (isAnalyzing)
          _AnalysisProgress()
        else
          _AnalyzeButton(
            onPressed: () => _handleImageUpload(ref),
          ),
      ],
    );
  }
}

// Enhanced Upload Area Component
class _UploadArea extends StatefulWidget {
  final VoidCallback onTap;
  final bool isAnalyzing;

  const _UploadArea({
    required this.onTap,
    required this.isAnalyzing,
  });

  @override
  State<_UploadArea> createState() => _UploadAreaState();
}

class _UploadAreaState extends State<_UploadArea>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.isAnalyzing ? null : widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 320,
          decoration: BoxDecoration(
            color: _isHovered
                ? AppColors.surface
                : AppColors.surface.withOpacity(0.5),
            border: Border.all(
              color: _isHovered ? AppColors.primary : AppColors.border,
              width: _isHovered ? 2 : 1.5,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            children: [
              // Animated border effect
              if (_isHovered)
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primary.withOpacity(
                            0.3 + (_pulseController.value * 0.2),
                          ),
                          width: 2,
                        ),
                      ),
                    );
                  },
                ),
              // Content
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.receipt_long_outlined,
                        size: 48,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Drop your receipt here',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'or tap to browse files',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.onSurfaceMuted,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.image_outlined,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Supports JPG, PNG, PDF',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Analysis Progress Component
class _AnalysisProgress extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.border,
              width: 1,
            ),
          ),
          child: const Column(
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Analyzing receipt...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'This may take a moment',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.onSurfaceMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Analyze Button Component
class _AnalyzeButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _AnalyzeButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.bolt_outlined, size: 20),
        label: const Text(
          'Analyze Receipt',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Tab 2: Manual Entry
// -----------------------------------------------------------------------------
class _ManualEntryTab extends StatefulWidget {
  final Function(ReceiptModel) onSave;
  const _ManualEntryTab({required this.onSave});

  @override
  State<_ManualEntryTab> createState() => _ManualEntryTabState();
}

class _ManualEntryTabState extends State<_ManualEntryTab> {
  final _formKey = GlobalKey<FormState>();
  String _storeName = '';
  DateTime _selectedDate = DateTime.now();
  final List<ReceiptItem> _items = [
    ReceiptItem(name: '', quantity: 1.0, price: 0.0, total: 0.0)
  ];

  void _addItemRow() {
    setState(() {
      _items.add(ReceiptItem(name: '', quantity: 1.0, price: 0.0, total: 0.0));
    });
  }

  void _removeItemRow(int index) {
    setState(() {
      if (_items.length > 1) {
        _items.removeAt(index);
      }
    });
  }

  void _calculateAndSave() {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final total =
        _items.fold(0.0, (sum, item) => sum + item.price * item.quantity);

    final manualReceipt = ReceiptModel(
      id: '',
      name: 'Manual Entry: $_storeName',
      date: _selectedDate,
      store: _storeName,
      items: _items
          .map((i) => ReceiptItem(
              name: i.name,
              price: i.price,
              quantity: i.quantity,
              total: i.price * i.quantity))
          .toList(),
      total: total,
    );

    // Set the resulting receipt in the provider and start the save flow
    widget.onSave(manualReceipt);
  }

  @override
  Widget build(BuildContext context) {
    final total = _items.fold(
      0.0,
      (sum, item) => sum + (item.price * item.quantity),
    );

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Store Name
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Store Name',
              hintText: 'e.g., Walmart, Target',
              prefixIcon: Icon(Icons.store_outlined),
            ),
            onSaved: (v) => _storeName = v ?? '',
            validator: (v) => v!.isEmpty ? 'Store name is required' : null,
            style: const TextStyle(color: AppColors.onSurface),
          ),
          const SizedBox(height: 20),
          // Date Picker
          InkWell(
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.dark(
                        primary: AppColors.primary,
                        onPrimary: Colors.white,
                        surface: AppColors.surface,
                        onSurface: AppColors.onSurface,
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (date != null) setState(() => _selectedDate = date);
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.border,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Date',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.onSurfaceMuted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat.yMMMMd().format(_selectedDate),
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppColors.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    color: AppColors.onSurfaceMuted,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Items Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Items',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              TextButton.icon(
                onPressed: _addItemRow,
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: const Text('Add Item'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Items List
          Expanded(
            child: _items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 64,
                          color: AppColors.onSurfaceMuted.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No items added yet',
                          style: TextStyle(
                            color: AppColors.onSurfaceMuted,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: _addItemRow,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add First Item'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ManualItemRow(
                          key: ValueKey(_items[index]),
                          item: _items[index],
                          onChanged: (updatedItem) =>
                              setState(() => _items[index] = updatedItem),
                          onRemove: () => _removeItemRow(index),
                          canRemove: _items.length > 1,
                        ),
                      );
                    },
                  ),
          ),

          // Total and Save Button
          if (_items.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.border,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                  Text(
                    NumberFormat.currency(symbol: '\$').format(total),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _calculateAndSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Save Manual Entry',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ManualItemRow extends StatelessWidget {
  final ReceiptItem item;
  final ValueChanged<ReceiptItem> onChanged;
  final VoidCallback onRemove;
  final bool canRemove;

  const _ManualItemRow({
    super.key,
    required this.item,
    required this.onChanged,
    required this.onRemove,
    this.canRemove = true,
  });

  @override
  Widget build(BuildContext context) {
    final total = item.price * item.quantity;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.border,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Item Name
          TextFormField(
            initialValue: item.name,
            decoration: const InputDecoration(
              labelText: 'Item Name',
              hintText: 'Enter item name',
              prefixIcon: Icon(Icons.shopping_bag_outlined),
            ),
            onChanged: (v) => onChanged(ReceiptItem(
              name: v,
              quantity: item.quantity,
              price: item.price,
              total: item.total,
            )),
            validator: (v) => v!.isEmpty ? 'Required' : null,
            style: const TextStyle(color: AppColors.onSurface),
          ),
          const SizedBox(height: 16),
          // Quantity and Price Row
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: item.quantity.toStringAsFixed(1),
                  decoration: const InputDecoration(
                    labelText: 'Quantity',
                    prefixIcon: Icon(Icons.numbers_outlined),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (v) => onChanged(ReceiptItem(
                    name: item.name,
                    quantity: double.tryParse(v) ?? 1.0,
                    price: item.price,
                    total: item.total,
                  )),
                  style: const TextStyle(color: AppColors.onSurface),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  initialValue: item.price.toStringAsFixed(2),
                  decoration: const InputDecoration(
                    labelText: 'Price',
                    prefixIcon: Icon(Icons.attach_money_outlined),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (v) => onChanged(ReceiptItem(
                    name: item.name,
                    quantity: item.quantity,
                    price: double.tryParse(v) ?? 0.0,
                    total: item.total,
                  )),
                  validator: (v) =>
                      (double.tryParse(v ?? '') ?? -1) < 0 ? 'Invalid' : null,
                  style: const TextStyle(color: AppColors.onSurface),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Total and Remove Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Total: ${NumberFormat.currency(symbol: '\$').format(total)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
              if (canRemove)
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppColors.error,
                    size: 20,
                  ),
                  onPressed: onRemove,
                  tooltip: 'Remove item',
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Shared: Results Section
// -----------------------------------------------------------------------------
class _ResultsSection extends ConsumerWidget {
  final ReceiptModel receipt;
  final Function(ReceiptModel) onSave;
  final VoidCallback onClear;
  const _ResultsSection(
      {required this.receipt, required this.onSave, required this.onClear});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    final currency = settingsAsync.valueOrNull?.currency ?? Currency.USD;
    final formatter = NumberFormat.currency(symbol: currency.name, decimalDigits: 2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Success Header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.success.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.success.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  color: AppColors.success,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Analysis Complete',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Review the details below',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.onSurfaceMuted,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onClear,
                icon: const Icon(
                  Icons.close,
                  color: AppColors.onSurfaceMuted,
                ),
                tooltip: 'Clear and start over',
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Receipt Info Cards
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.border,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Store',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.onSurfaceMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      receipt.store,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.border,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Date',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.onSurfaceMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat.yMMMMd().format(receipt.date),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Items List
        Text(
          'Items (${receipt.items.length})',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 16),
        ...receipt.items.asMap().entries.map((entry) {
          final item = entry.value;
          final index = entry.key;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: AppColors.border,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Qty: ${item.quantity.toStringAsFixed(1)} × ${formatter.format(item.price)}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.onSurfaceMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  formatter.format(item.total),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 24),

        // Grand Total
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primary.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Grand Total',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
              Text(
                formatter.format(receipt.total),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),

        // Save Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => onSave(receipt),
            icon: const Icon(Icons.save_outlined, size: 20),
            label: const Text(
              'Save Receipt',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------------------
// Save Receipt Modal/Dialog
// -----------------------------------------------------------------------------
class _SaveReceiptModal extends ConsumerStatefulWidget {
  final ReceiptModel receipt;
  const _SaveReceiptModal({required this.receipt});

  @override
  ConsumerState<_SaveReceiptModal> createState() => __SaveReceiptModalState();
}

class __SaveReceiptModalState extends ConsumerState<_SaveReceiptModal> {
  late TextEditingController _nameController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    // Generate default name based on settings
    final settingsAsync = ref.read(settingsProvider);
    final settings = settingsAsync.valueOrNull ?? SettingsState();
    final store = widget.receipt.store;
    final date = DateFormat('MM/dd/yyyy').format(widget.receipt.date);

    String defaultName = switch (settings.namingFormat) {
      NamingFormat.storeDate => '$store - $date',
      NamingFormat.dateStore => '$date - $store',
      NamingFormat.storeOnly => store,
      NamingFormat.dateOnly => date,
    };

    _nameController = TextEditingController(text: defaultName);
  }

  void _save() async {
    if (_nameController.text.trim().isEmpty) return;

    setState(() => _isSaving = true);
    final success = await ref.read(receiptEntryProvider.notifier).saveReceipt(
          _nameController.text.trim(),
          widget.receipt,
        );
    if (mounted) {
      Navigator.of(context).pop(success);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);
    final currency = settingsAsync.valueOrNull?.currency ?? Currency.USD;
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(
          color: AppColors.border,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.save_outlined,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Save Receipt',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: AppColors.onSurface,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.of(context).pop(false),
                  color: AppColors.onSurfaceMuted,
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Give your receipt a name',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.onSurfaceMuted,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Receipt Name',
                hintText: 'e.g., Grocery Store - January 15',
              ),
              validator: (v) =>
                  v!.trim().isEmpty ? 'Name cannot be empty' : null,
              style: const TextStyle(color: AppColors.onSurface),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.onSurfaceMuted,
                    ),
                  ),
                  Text(
                    NumberFormat.currency(symbol: currency.name).format(
                      widget.receipt.total,
                    ),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text(
                            'Save',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
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

// Quick Add Floating Button
class _QuickAddButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary,
            AppColors.primaryLight,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.4),
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/voice-add'),
          borderRadius: BorderRadius.circular(32),
          child: const Icon(
            Icons.mic,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }
}
