import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hisabi/core/models/receipt_model.dart';
import 'package:hisabi/core/constants/app_theme.dart';
import 'package:hisabi/core/utils/theme_extensions.dart';
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SaveReceiptModal(receipt: receipt),
    ).then((saved) {
      if (saved == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Receipt saved successfully!'),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
            shape: const StadiumBorder(),
            margin: const EdgeInsets.all(16),
          ),
        );
        ref.read(receiptEntryProvider.notifier).clearResult();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final entryState = ref.watch(receiptEntryProvider);
    final isAnalysisComplete = entryState.analyzedReceipt != null;

    return Scaffold(
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            const SliverAppBar.large(
              title: Text('Add Receipt'),
              centerTitle: false,
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
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
      ),
      floatingActionButton: isAnalysisComplete 
          ? null 
          : FloatingActionButton.large(
              onPressed: () => context.push('/voice-add'),
              child: const Icon(Icons.mic),
            ).animate().scale(delay: 400.ms),
    );
  }

  Widget _buildEntryTabs(BuildContext context, bool isAnalyzing) {
    return Column(
      children: [
        const SizedBox(height: 8),
        Center(
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(32),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                color: Theme.of(context).colorScheme.primary,
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Theme.of(context).colorScheme.onPrimary,
              unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              tabs: const [
                Tab(text: 'Upload'),
                Tab(text: 'Manual'),
              ],
            ),
          ),
        ).animate().fadeIn().slideY(begin: 0.2),
        const SizedBox(height: 32),
        SizedBox(
          height: 550, // Fixed height for tabs content
          child: TabBarView(
            controller: _tabController,
            children: [
              _UploadReceiptTab(isAnalyzing: isAnalyzing),
              _ManualEntryTab(onSave: (r) => _startSaveReceiptFlow(r)),
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
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => _showPicker(context, ref),
          child: Container(
            width: double.infinity,
            height: 320,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: colorScheme.outlineVariant.withOpacity(0.5),
                width: 2,
              ),
            ),
            child: isAnalyzing 
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 24),
                    Text('Analyzing...', style: Theme.of(context).textTheme.titleMedium),
                  ],
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_a_photo_outlined, size: 64, color: colorScheme.primary),
                    const SizedBox(height: 20),
                    Text('Tap to upload receipt', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('AI will extract details for you', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
                  ],
                ),
          ),
        ).animate().fadeIn().scale(),
      ],
    );
  }

  void _showPicker(BuildContext context, WidgetRef ref) {
    final picker = ImagePicker();
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () async {
                Navigator.pop(context);
                final img = await picker.pickImage(source: ImageSource.camera);
                if (img != null) ref.read(receiptEntryProvider.notifier).analyzeImage(File(img.path));
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () async {
                Navigator.pop(context);
                final img = await picker.pickImage(source: ImageSource.gallery);
                if (img != null) ref.read(receiptEntryProvider.notifier).analyzeImage(File(img.path));
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _ManualEntryTab extends StatefulWidget {
  final Function(ReceiptModel) onSave;
  const _ManualEntryTab({required this.onSave});

  @override
  State<_ManualEntryTab> createState() => _ManualEntryTabState();
}

class _ManualEntryTabState extends State<_ManualEntryTab> {
  final _storeController = TextEditingController();
  final _totalController = TextEditingController();
  DateTime _date = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        children: [
          TextField(
            controller: _storeController,
            decoration: InputDecoration(
              labelText: 'Store Name', 
              prefixIcon: const Icon(Icons.store),
              filled: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _totalController,
            decoration: InputDecoration(
              labelText: 'Total Amount', 
              prefixIcon: const Icon(Icons.attach_money),
              filled: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 16),
          ListTile(
            title: const Text('Date', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(DateFormat.yMMMd().format(_date)),
            leading: const Icon(Icons.calendar_today),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            tileColor: Theme.of(context).colorScheme.surfaceContainer,
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: _date,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (d != null) setState(() => _date = d);
            },
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                widget.onSave(ReceiptModel(
                  id: '',
                  name: '',
                  date: _date,
                  store: _storeController.text,
                  items: [],
                  total: double.tryParse(_totalController.text) ?? 0,
                ));
              },
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Add Receipt', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ).animate().fadeIn(),
    );
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
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const Icon(Icons.check_circle, size: 64, color: Colors.green),
                const SizedBox(height: 20),
                const Text('AI Analysis Complete', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
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
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: onClear,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Clear'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton(
                onPressed: () => onSave(receipt),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Confirm & Save'),
              ),
            ),
          ],
        ),
      ],
    ).animate().fadeIn();
  }

  Widget _buildInfoRow(BuildContext context, String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 16)),
        Text(value, style: TextStyle(
          fontWeight: isBold ? FontWeight.w900 : FontWeight.bold,
          fontSize: isBold ? 20 : 16,
          color: isBold ? Theme.of(context).colorScheme.primary : null,
        )),
      ],
    );
  }
}

class _SaveReceiptModal extends StatefulWidget {
  final ReceiptModel receipt;
  const _SaveReceiptModal({required this.receipt});

  @override
  State<_SaveReceiptModal> createState() => _SaveReceiptModalState();
}

class _SaveReceiptModalState extends State<_SaveReceiptModal> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.text = '${widget.receipt.store} - ${DateFormat.yMd().format(widget.receipt.date)}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 32),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Save Receipt', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Receipt Name',
              filled: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Save', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
