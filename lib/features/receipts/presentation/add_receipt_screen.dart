import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hisabi/core/models/receipt_model.dart';
import 'package:hisabi/features/receipts/providers/receipt_provider.dart';

class AddReceiptScreen extends ConsumerStatefulWidget {
  const AddReceiptScreen({super.key});

  @override
  ConsumerState<AddReceiptScreen> createState() => _AddReceiptScreenState();
}

class _AddReceiptScreenState extends ConsumerState<AddReceiptScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final GlobalKey<_ManualEntryTabState> _manualEntryKey = GlobalKey<_ManualEntryTabState>();

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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SaveReceiptModal(receipt: receipt),
    ).then((saved) {
      if (saved == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Theme.of(context).colorScheme.onPrimary),
                const SizedBox(width: 12),
                const Text('Receipt saved successfully!', style: TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.all(20),
          ),
        );
        ref.read(receiptEntryProvider.notifier).clearResult();
        _manualEntryKey.currentState?.resetFields();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final entryState = ref.watch(receiptEntryProvider);
    final isAnalysisComplete = entryState.analyzedReceipt != null;

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          const SliverAppBar.large(
            title: Text('Add Receipt'),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            sliver: SliverToBoxAdapter(
              child: isAnalysisComplete
                  ? _ResultsSection(
                      receipt: entryState.analyzedReceipt!,
                      onSave: _startSaveReceiptFlow,
                      onClear: ref.read(receiptEntryProvider.notifier).clearResult,
                    )
                  : _buildEntryTabs(context, entryState.isAnalyzing),
            ),
          ),
        ],
      ),
      floatingActionButton: isAnalysisComplete 
          ? null 
          : Padding(
              padding: const EdgeInsets.only(bottom: 80),
              child: FloatingActionButton.large(
                onPressed: () => context.push('/voice-add'),
                child: const Icon(Icons.mic_rounded, size: 32),
              ).animate().scale(delay: 400.ms),
            ),
    );
  }

  Widget _buildEntryTabs(BuildContext context, bool isAnalyzing) {
    return Column(
      children: [
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Theme.of(context).colorScheme.primary,
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            dividerColor: Colors.transparent,
            labelColor: Theme.of(context).colorScheme.onPrimary,
            unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
            labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            tabs: const [
              Tab(text: 'SCAN RECEIPT'),
              Tab(text: 'MANUAL ENTRY'),
            ],
          ),
        ).animate().fadeIn().slideY(begin: 0.2),
        const SizedBox(height: 32),
        SizedBox(
          height: 480,
          child: TabBarView(
            controller: _tabController,
            children: [
              _UploadReceiptTab(isAnalyzing: isAnalyzing),
              _ManualEntryTab(
                key: _manualEntryKey,
                onSave: _startSaveReceiptFlow,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _UploadReceiptTab extends ConsumerWidget {
  final bool isAnalyzing;
  const _UploadReceiptTab({required this.isAnalyzing});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        GestureDetector(
          onTap: isAnalyzing ? null : () => _showPicker(context, ref),
          child: Container(
            width: double.infinity,
            height: 300,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh.withOpacity(0.5),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: colorScheme.outlineVariant.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: isAnalyzing 
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 24),
                    Text(
                      'Analyzing receipt...', 
                      style: TextStyle(fontWeight: FontWeight.w800, color: colorScheme.primary),
                    ),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: colorScheme.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.add_a_photo_rounded, size: 48, color: colorScheme.primary),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Tap to scan or upload', 
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Extract details with AI', 
                      style: TextStyle(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
          ),
        ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95)),
      ],
    );
  }

  void _showPicker(BuildContext context, WidgetRef ref) {
    final picker = ImagePicker();
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                leading: const Icon(Icons.camera_alt_rounded),
                title: const Text('Take a photo', style: TextStyle(fontWeight: FontWeight.w800)),
                onTap: () async {
                  Navigator.pop(context);
                  final img = await picker.pickImage(source: ImageSource.camera);
                  if (img != null) ref.read(receiptEntryProvider.notifier).analyzeImage(File(img.path));
                },
              ),
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                leading: const Icon(Icons.photo_library_rounded),
                title: const Text('Choose from gallery', style: TextStyle(fontWeight: FontWeight.w800)),
                onTap: () async {
                  Navigator.pop(context);
                  final img = await picker.pickImage(source: ImageSource.gallery);
                  if (img != null) ref.read(receiptEntryProvider.notifier).analyzeImage(File(img.path));
                },
              ),
              const SizedBox(height: 20),
            ],
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
  final _storeController = TextEditingController();
  final _totalController = TextEditingController();
  DateTime _date = DateTime.now();

  void resetFields() {
    setState(() {
      _storeController.clear();
      _totalController.clear();
      _date = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height - 300,
        ),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 120),
          child: Column(
            children: [
              TextField(
                controller: _storeController,
                decoration: const InputDecoration(
                  labelText: 'Store Name', 
                  prefixIcon: Icon(Icons.store_rounded),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _totalController,
                decoration: const InputDecoration(
                  labelText: 'Total Amount', 
                  prefixIcon: Icon(Icons.attach_money_rounded),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (d != null) setState(() => _date = d);
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHigh.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today_rounded, color: Theme.of(context).colorScheme.primary, size: 20),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Date', 
                            style: TextStyle(
                              fontSize: 12, 
                              fontWeight: FontWeight.w700, 
                              color: Theme.of(context).colorScheme.onSurfaceVariant
                            ),
                          ),
                          Text(
                            DateFormat.yMMMd().format(_date), 
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    widget.onSave(
                      ReceiptModel(
                        id: '',
                        name: '',
                        date: _date,
                        store: _storeController.text,
                        items: [],
                        total: double.tryParse(_totalController.text) ?? 0,
                      ),
                    );
                  },
                  child: const Text('Confirm Entry'),
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn();
  }
}

class _ResultsSection extends ConsumerWidget {
  final ReceiptModel receipt;
  final Function(ReceiptModel) onSave;
  final VoidCallback onClear;
  const _ResultsSection({required this.receipt, required this.onSave, required this.onClear});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                  child: const Icon(Icons.check_rounded, size: 32, color: Colors.white),
                ),
                const SizedBox(height: 20),
                const Text('AI Scan Complete', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22)),
                const SizedBox(height: 32),
                _buildInfoRow(context, 'Store', receipt.store),
                const Divider(height: 32),
                _buildInfoRow(context, 'Date', DateFormat.yMMMd().format(receipt.date)),
                const Divider(height: 32),
                _buildInfoRow(context, 'Total', '\$${receipt.total.toStringAsFixed(2)}', isBold: true),
              ],
            ),
          ),
        ),
        const SizedBox(height: 40),
        Padding(
          padding: const EdgeInsets.only(bottom: 100),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onClear,
                  child: const Text('Discard'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => onSave(receipt),
                  child: const Text('Save Receipt'),
                ),
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  Widget _buildInfoRow(BuildContext context, String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.w700)),
        Text(value, style: TextStyle(
          fontWeight: isBold ? FontWeight.w900 : FontWeight.w800,
          fontSize: isBold ? 20 : 16,
          color: isBold ? Theme.of(context).colorScheme.primary : null,
        )),
      ],
    );
  }
}

class _SaveReceiptModal extends ConsumerStatefulWidget {
  final ReceiptModel receipt;
  const _SaveReceiptModal({required this.receipt});

  @override
  ConsumerState<_SaveReceiptModal> createState() => _SaveReceiptModalState();
}

class _SaveReceiptModalState extends ConsumerState<_SaveReceiptModal> {
  final _controller = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _controller.text = '${widget.receipt.store} - ${DateFormat.yMd().format(widget.receipt.date)}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        24, 
        24, 
        24, 
        MediaQuery.of(context).viewInsets.bottom + 
        MediaQuery.of(context).padding.bottom + 
        120
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Final Details', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24)),
          const SizedBox(height: 24),
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Display Name',
              hintText: 'e.g. Grocery Shopping',
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : () async {
                setState(() => _isSaving = true);
                final success = await ref.read(receiptEntryProvider.notifier).saveReceipt(_controller.text, widget.receipt);
                if (mounted) {
                  Navigator.pop(context, success);
                }
              },
              child: _isSaving 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Finish & Save'),
            ),
          ),
        ],
      ),
    );
  }
}
