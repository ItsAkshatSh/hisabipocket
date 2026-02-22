import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisabi/features/reports/models/export_options.dart';
import 'package:hisabi/features/reports/providers/export_provider.dart';
import 'package:intl/intl.dart';

class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key});

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  ExportFormat _selectedFormat = ExportFormat.csv;
  DateTimeRange? _dateRange;
  bool _includeItems = true;
  bool _includeCategories = true;
  bool _includeSplits = true;

  Future<void> _selectDateRange() async {
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    );
    if (range != null) {
      setState(() => _dateRange = range);
    }
  }

  Future<void> _export() async {
    final options = ExportOptions(
      format: _selectedFormat,
      startDate: _dateRange?.start,
      endDate: _dateRange?.end,
      includeItems: _includeItems,
      includeCategories: _includeCategories,
      includeSplits: _includeSplits,
    );

    await ref.read(exportProvider.notifier).exportReceipts(options);
    
    final exportAsync = ref.read(exportProvider);
    exportAsync.whenData((filePath) {
      if (filePath != null && mounted) {
        ref.read(exportProvider.notifier).shareFile(filePath);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Export completed and ready to share')),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final exportAsync = ref.watch(exportProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Receipts'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Export Format',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SegmentedButton<ExportFormat>(
              segments: const [
                ButtonSegment(
                  value: ExportFormat.csv,
                  label: Text('CSV'),
                  icon: Icon(Icons.table_chart),
                ),
                ButtonSegment(
                  value: ExportFormat.pdf,
                  label: Text('PDF'),
                  icon: Icon(Icons.picture_as_pdf),
                ),
              ],
              selected: {_selectedFormat},
              onSelectionChanged: (value) {
                setState(() => _selectedFormat = value.first);
              },
            ),
            const SizedBox(height: 32),
            Text(
              'Date Range',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _selectDateRange,
              icon: const Icon(Icons.calendar_today),
              label: Text(
                _dateRange == null
                    ? 'Select Date Range (Optional)'
                    : '${DateFormat.yMMMd().format(_dateRange!.start)} - ${DateFormat.yMMMd().format(_dateRange!.end)}',
              ),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
            if (_dateRange != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: TextButton(
                  onPressed: () => setState(() => _dateRange = null),
                  child: const Text('Clear Date Range'),
                ),
              ),
            const SizedBox(height: 32),
            Text(
              'Options',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Include Item Details'),
              subtitle: const Text('Include individual items in export'),
              value: _includeItems,
              onChanged: (value) => setState(() => _includeItems = value),
            ),
            SwitchListTile(
              title: const Text('Include Categories'),
              subtitle: const Text('Include category information'),
              value: _includeCategories,
              onChanged: (value) => setState(() => _includeCategories = value),
            ),
            SwitchListTile(
              title: const Text('Include Splits'),
              subtitle: const Text('Include receipt split information'),
              value: _includeSplits,
              onChanged: (value) => setState(() => _includeSplits = value),
            ),
            const SizedBox(height: 40),
            exportAsync.when(
              data: (_) => ElevatedButton(
                onPressed: _export,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: const Text('Export & Share'),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Column(
                children: [
                  Text('Error: $err', style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _export,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: const Text('Retry Export'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }
}

