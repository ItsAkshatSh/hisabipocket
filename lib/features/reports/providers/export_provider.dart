import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisabi/core/models/receipt_model.dart';
import 'package:hisabi/features/receipts/providers/receipts_store.dart';
import 'package:hisabi/features/reports/models/export_options.dart';
import 'package:hisabi/features/settings/providers/settings_provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

final exportProvider = StateNotifierProvider<ExportNotifier, AsyncValue<String?>>((ref) {
  return ExportNotifier(ref);
});

class ExportNotifier extends StateNotifier<AsyncValue<String?>> {
  final Ref _ref;
  
  ExportNotifier(this._ref) : super(const AsyncValue.data(null));

  Future<void> exportReceipts(ExportOptions options) async {
    state = const AsyncValue.loading();
    
    try {
      final receiptsAsync = _ref.read(receiptsStoreProvider);
      final receipts = receiptsAsync.valueOrNull ?? [];
      
      var filteredReceipts = receipts;
      
      if (options.startDate != null) {
        filteredReceipts = filteredReceipts.where((r) => !r.date.isBefore(options.startDate!)).toList();
      }
      
      if (options.endDate != null) {
        filteredReceipts = filteredReceipts.where((r) => !r.date.isAfter(options.endDate!)).toList();
      }

      final settingsAsync = _ref.read(settingsProvider);
      final currency = settingsAsync.valueOrNull?.currency ?? Currency.USD;
      
      if (options.format == ExportFormat.csv) {
        final csv = _generateCSV(filteredReceipts, currency);
        final file = await _saveToFile(csv, 'receipts_export.csv');
        state = AsyncValue.data(file.path);
      } else {
        final pdf = _generatePDF(filteredReceipts, currency);
        final file = await _saveToFile(pdf, 'receipts_export.pdf');
        state = AsyncValue.data(file.path);
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  String _generateCSV(List<ReceiptModel> receipts, Currency currency) {
    final buffer = StringBuffer();
    final formatter = NumberFormat.currency(symbol: currency.name, decimalDigits: 2);
    final dateFormatter = DateFormat('yyyy-MM-dd');
    
    buffer.writeln('Date,Store,Total,Items Count,Category');
    
    for (final receipt in receipts) {
      final category = receipt.primaryCategory?.name ?? receipt.calculatedPrimaryCategory?.name ?? 'Other';
      buffer.writeln([
        dateFormatter.format(receipt.date),
        '"${receipt.store}"',
        formatter.format(receipt.total),
        receipt.items.length.toString(),
        category,
      ].join(','));
    }
    
    return buffer.toString();
  }

  String _generatePDF(List<ReceiptModel> receipts, Currency currency) {
    final formatter = NumberFormat.currency(symbol: currency.name, decimalDigits: 2);
    final dateFormatter = DateFormat('yyyy-MM-dd');
    
    final buffer = StringBuffer();
    buffer.writeln('RECEIPTS EXPORT');
    buffer.writeln('Generated: ${DateFormat.yMMMd().format(DateTime.now())}');
    buffer.writeln('Total Receipts: ${receipts.length}');
    buffer.writeln('');
    buffer.writeln('=' * 50);
    buffer.writeln('');
    
    for (final receipt in receipts) {
      buffer.writeln('Date: ${dateFormatter.format(receipt.date)}');
      buffer.writeln('Store: ${receipt.store}');
      buffer.writeln('Total: ${formatter.format(receipt.total)}');
      if (receipt.items.isNotEmpty) {
        buffer.writeln('Items:');
        for (final item in receipt.items) {
          buffer.writeln('  - ${item.name}: ${formatter.format(item.total)}');
        }
      }
      buffer.writeln('');
      buffer.writeln('-' * 50);
      buffer.writeln('');
    }
    
    return buffer.toString();
  }

  Future<File> _saveToFile(String content, String filename) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$filename');
    await file.writeAsString(content);
    return file;
  }

  Future<void> shareFile(String filePath) async {
    try {
      await Share.shareXFiles([XFile(filePath)]);
    } catch (e) {
      throw Exception('Failed to share file: $e');
    }
  }
}

