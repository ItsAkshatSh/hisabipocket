import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hisabi/core/models/receipt_model.dart';
import 'package:hisabi/core/constants/app_theme.dart';
import 'package:hisabi/core/utils/theme_extensions.dart';
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

  void _startSaveReceiptFlow(ReceiptModel receipt) {
    showDialog(
      context: context,
      builder: (context) => _SaveReceiptModal(receipt: receipt),
    ).then((saved) {
      if (saved == true) {
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
                  child: Icon(
                    Icons.check,
                    color: Theme.of(context).colorScheme.onPrimary,
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
            backgroundColor: context.surfaceColor,
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
                Icon(Icons.error_outline,
                    color: Theme.of(context).colorScheme.onError),
                const SizedBox(width: 12),
                Expanded(child: Text('Analysis Failed: ${next.analysisError}')),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
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
                        style:
                            Theme.of(context).textTheme.displayMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: context.onSurfaceColor,
                                ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              FadeInWidget(
                delay: const Duration(milliseconds: 100),
                child: Text(
                  'Upload a receipt image or enter details manually',
                  style: TextStyle(
                    fontSize: 14,
                    color: context.onSurfaceMutedColor,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              (isAnalysisComplete
                  ? FadeInWidget(
                      child: _ResultsSection(
                        receipt: entryState.analyzedReceipt!,
                        onSave: _startSaveReceiptFlow,
                        onClear:
                            ref.read(receiptEntryProvider.notifier).clearResult,
                      ),
                    )
                  : _buildEntryTabs(context, entryState.isAnalyzing)),
            ],
          ),
        ),
        Positioned(
          bottom: isMobile ? 80 : 24,
          right: isMobile ? 20 : 32,
          child: _QuickAddButton(),
        ),
      ],
    );
  }

  Widget _buildEntryTabs(BuildContext context, bool isAnalyzing) {
    final screenHeight = MediaQuery.of(context).size.height;
    return FadeInWidget(
      delay: const Duration(milliseconds: 150),
      child: Column(
        children: [
          Container(
            constraints: const BoxConstraints(minHeight: 64),
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: context.borderColor,
                width: 1,
              ),
            ),
            padding: const EdgeInsets.all(4),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: context.primaryColor,
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Theme.of(context).colorScheme.onPrimary,
              unselectedLabelColor: context.onSurfaceMutedColor,
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
          const SizedBox(height: 24),
          SizedBox(
            height: screenHeight * 0.75, // Increased height for better fit
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

class _UploadReceiptTab extends ConsumerWidget {
  final bool isAnalyzing;
  const _UploadReceiptTab({required this.isAnalyzing});

  void _handleImageUpload(BuildContext context, WidgetRef ref) async {
    final ImagePicker picker = ImagePicker();
    
    showModalBottomSheet(
      context: context,
      backgroundColor: context.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take Photo'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image = await picker.pickImage(source: ImageSource.camera);
                if (image != null) {
                  ref.read(receiptEntryProvider.notifier).analyzeImage(File(image.path));
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.image_outlined),
              title: const Text('Choose from Gallery'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                if (image != null) {
                  ref.read(receiptEntryProvider.notifier).analyzeImage(File(image.path));
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _UploadArea(
          onTap: () => _handleImageUpload(context, ref),
          isAnalyzing: isAnalyzing,
        ),
        const SizedBox(height: 40),
        if (isAnalyzing)
          const _AnalysisProgress()
        else
          _AnalyzeButton(
            onPressed: () => _handleImageUpload(context, ref),
          ),
      ],
    );
  }
}

class _UploadArea extends StatefulWidget {
  final VoidCallback onTap;
  final bool isAnalyzing;

  const _UploadArea({
    super.key,
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
                ? context.surfaceColor
                : context.surfaceColor.withOpacity(0.5),
            border: Border.all(
              color: _isHovered ? context.primaryColor : context.borderColor,
              width: _isHovered ? 2 : 1.5,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            children: [
              if (_isHovered)
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    return Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: context.primaryColor.withOpacity(
                            0.3 + (_pulseController.value * 0.2),
                          ),
                          width: 2,
                        ),
                      ),
                    );
                  },
                ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: context.primaryColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.receipt_long_outlined,
                        size: 48,
                        color: context.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Drop your receipt here',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'or tap to browse files',
                      style: TextStyle(
                        fontSize: 14,
                        color: context.onSurfaceMutedColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: context.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.image_outlined,
                            size: 16,
                            color: context.primaryColor,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Supports JPG, PNG, PDF',
                            style: TextStyle(
                              fontSize: 12,
                              color: context.primaryColor,
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

class _AnalysisProgress extends StatelessWidget {
  const _AnalysisProgress({super.key});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: context.borderColor,
              width: 1,
            ),
          ),
          child: Column(
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(context.primaryColor),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Analyzing receipt...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This may take a moment',
                style: TextStyle(
                  fontSize: 14,
                  color: context.onSurfaceMutedColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AnalyzeButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _AnalyzeButton({super.key, required this.onPressed});

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
          backgroundColor: context.primaryColor,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}

class _ManualEntryTab extends StatefulWidget {
  final Function(ReceiptModel) onSave;
  const _ManualEntryTab({super.key, required this.onSave});

  @override
  State<_ManualEntryTab> createState() => _ManualEntryTabState();
}

class _ManualEntryTabState extends State<_ManualEntryTab> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  String _storeName = '';
  DateTime _selectedDate = DateTime.now();
  final List<ReceiptItem> _items = [
    ReceiptItem(name: '', quantity: 1.0, price: 0.0, total: 0.0)
  ];

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _addItemRow() {
    setState(() {
      _items.add(ReceiptItem(name: '', quantity: 1.0, price: 0.0, total: 0.0));
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
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
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Store Name',
              hintText: 'e.g., Walmart, Target',
              prefixIcon: Icon(Icons.store_outlined),
              isDense: true,
            ),
            onSaved: (v) => _storeName = v ?? '',
            validator: (v) => v!.isEmpty ? 'Store name is required' : null,
            style: TextStyle(color: context.onSurfaceColor),
          ),
          const SizedBox(height: 16),
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
                      colorScheme: ColorScheme.dark(
                        primary: context.primaryColor,
                        onPrimary: Colors.white,
                        surface: context.surfaceColor,
                        onSurface: context.onSurfaceColor,
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: context.surfaceColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: context.borderColor,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    color: context.primaryColor,
                    size: 18,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Date',
                          style: TextStyle(
                            fontSize: 11,
                            color: context.onSurfaceMutedColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          DateFormat.yMMMMd().format(_selectedDate),
                          style: TextStyle(
                            fontSize: 14,
                            color: context.onSurfaceColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: context.onSurfaceMutedColor,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Items',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton.icon(
                onPressed: _addItemRow,
                icon: const Icon(Icons.add_circle_outline, size: 16),
                label: const Text('Add Item', style: TextStyle(fontSize: 13)),
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 48,
                          color: context.onSurfaceMutedColor.withOpacity(0.5),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No items added yet',
                          style: TextStyle(
                            color: context.onSurfaceMutedColor,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: _addItemRow,
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add First Item'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            foregroundColor:
                                Theme.of(context).colorScheme.onPrimary,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    key: const PageStorageKey('manual_items_list'),
                    controller: _scrollController,
                    padding: const EdgeInsets.only(top: 4, bottom: 16),
                    itemCount: _items.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _ManualItemRow(
                          key: ValueKey('manual_item_$index'),
                          item: _items[index],
                          onChanged: (updatedItem) {
                            setState(() {
                              _items[index] = updatedItem;
                            });
                          },
                          onRemove: () => _removeItemRow(index),
                          canRemove: _items.length > 1,
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 12),
          if (_items.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: context.surfaceColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: context.borderColor,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    NumberFormat.currency(symbol: '\$').format(total),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: context.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _calculateAndSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Save Manual Entry',
                  style: TextStyle(
                    fontSize: 15,
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

class _ManualItemRow extends StatefulWidget {
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
  State<_ManualItemRow> createState() => _ManualItemRowState();
}

class _ManualItemRowState extends State<_ManualItemRow> {
  late TextEditingController _nameController;
  late TextEditingController _quantityController;
  late TextEditingController _priceController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item.name);
    _quantityController = TextEditingController(
      text: widget.item.quantity.toStringAsFixed(1),
    );
    _priceController = TextEditingController(
      text: widget.item.price.toStringAsFixed(2),
    );

    _nameController.addListener(_updateItem);
    _quantityController.addListener(_updateItem);
    _priceController.addListener(_updateItem);
  }

  @override
  void didUpdateWidget(_ManualItemRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.name != widget.item.name &&
        _nameController.text != widget.item.name) {
      _nameController.text = widget.item.name;
    }
    if (oldWidget.item.quantity != widget.item.quantity &&
        _quantityController.text != widget.item.quantity.toStringAsFixed(1)) {
      _quantityController.text = widget.item.quantity.toStringAsFixed(1);
    }
    if (oldWidget.item.price != widget.item.price &&
        _priceController.text != widget.item.price.toStringAsFixed(2)) {
      _priceController.text = widget.item.price.toStringAsFixed(2);
    }
  }

  void _updateItem() {
    final quantity =
        double.tryParse(_quantityController.text) ?? widget.item.quantity;
    final price = double.tryParse(_priceController.text) ?? widget.item.price;

    widget.onChanged(ReceiptItem(
      name: _nameController.text,
      quantity: quantity,
      price: price,
      total: quantity * price,
    ));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.item.price * widget.item.quantity;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: context.surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: context.borderColor.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Item Name',
              hintText: 'Enter item name',
              prefixIcon: Icon(Icons.shopping_bag_outlined, size: 18),
              isDense: true,
              contentPadding: EdgeInsets.symmetric(vertical: 8),
            ),
            validator: (v) => v!.isEmpty ? 'Required' : null,
            style: TextStyle(color: context.onSurfaceColor, fontSize: 14),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _quantityController,
                  decoration: const InputDecoration(
                    labelText: 'Qty',
                    prefixIcon: Icon(Icons.numbers_outlined, size: 18),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: TextStyle(color: context.onSurfaceColor, fontSize: 14),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(
                    labelText: 'Price',
                    prefixIcon: Icon(Icons.attach_money_outlined, size: 18),
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (v) =>
                      (double.tryParse(v ?? '') ?? -1) < 0 ? 'Invalid' : null,
                  style: TextStyle(color: context.onSurfaceColor, fontSize: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: context.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Total: ${NumberFormat.currency(symbol: '\$').format(total)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: context.primaryColor,
                  ),
                ),
              ),
              if (widget.canRemove)
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: AppColors.error,
                    size: 18,
                  ),
                  onPressed: widget.onRemove,
                  tooltip: 'Remove item',
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResultsSection extends ConsumerWidget {
  final ReceiptModel receipt;
  final Function(ReceiptModel) onSave;
  final VoidCallback onClear;
  const _ResultsSection(
      {super.key,
      required this.receipt,
      required this.onSave,
      required this.onClear});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    final currency = settingsAsync.valueOrNull?.currency ?? Currency.USD;
    final formatter =
        NumberFormat.currency(symbol: currency.name, decimalDigits: 2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.surfaceColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: context.borderColor,
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
                  color: context.surfaceColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: context.borderColor,
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
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        const Text(
          'Items',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
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
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: context.borderColor,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: context.primaryColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: context.primaryColor,
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
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: context.primaryColor,
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: context.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: context.primaryColor.withOpacity(0.3),
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
                ),
              ),
              Text(
                formatter.format(receipt.total),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: context.primaryColor,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
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
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
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

class _SaveReceiptModal extends ConsumerStatefulWidget {
  final ReceiptModel receipt;
  const _SaveReceiptModal({super.key, required this.receipt});

  @override
  ConsumerState<_SaveReceiptModal> createState() => __SaveReceiptModalState();
}

class __SaveReceiptModalState extends ConsumerState<_SaveReceiptModal> {
  late TextEditingController _nameController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
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
      backgroundColor: context.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: context.borderColor,
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
                    color: context.primaryColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.save_outlined,
                    color: context.primaryColor,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Save Receipt',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: context.onSurfaceColor,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.of(context).pop(false),
                  color: context.onSurfaceMutedColor,
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Give your receipt a name',
              style: TextStyle(
                fontSize: 14,
                color: context.onSurfaceMutedColor,
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
              style: TextStyle(color: context.onSurfaceColor),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total',
                    style: TextStyle(
                      fontSize: 14,
                      color: context.onSurfaceMutedColor,
                    ),
                  ),
                  Text(
                    NumberFormat.currency(symbol: currency.name).format(
                      widget.receipt.total,
                    ),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: context.primaryColor,
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
                      side: BorderSide(color: context.borderColor),
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
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _isSaving
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).colorScheme.onPrimary,
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

class _QuickAddButton extends StatelessWidget {
  const _QuickAddButton({super.key});
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
            context.primaryColor,
            context.primaryColor.withOpacity(0.8),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: context.primaryColor.withOpacity(0.4),
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
          child: Icon(
            Icons.mic,
            color: Theme.of(context).colorScheme.onPrimary,
            size: 28,
          ),
        ),
      ),
    );
  }
}
