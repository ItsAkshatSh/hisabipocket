import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hisabi/core/models/receipt_model.dart';
import 'package:hisabi/core/storage/storage_service.dart';
import 'package:hisabi/core/utils/theme_extensions.dart';
import 'package:hisabi/features/receipts/providers/receipts_store.dart';
import 'package:hisabi/features/settings/providers/settings_provider.dart';
import 'package:hisabi/features/auth/providers/auth_provider.dart';
import 'package:hisabi/features/settings/presentation/widgets/widget_preview.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cross_file/cross_file.dart';
import 'dart:io';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    final isMobile = MediaQuery.of(context).size.width < 600;

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: isMobile ? 20.0 : 32.0,
        right: isMobile ? 20.0 : 32.0,
        top: isMobile ? 20.0 : 32.0,
        bottom: isMobile ? 100.0 : 32.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Settings',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              letterSpacing: -1.0,
              color: context.onSurfaceColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Manage your app preferences and data',
            style: TextStyle(
              fontSize: 14,
              color: context.onSurfaceMutedColor,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 32),

          // Settings Sections
          settingsAsync.when(
            data: (settings) => Column(
              children: [
                _ThemeSection(settings: settings),
                const SizedBox(height: 24),
                _CurrencySection(settings: settings),
                const SizedBox(height: 24),
                _NamingFormatSection(settings: settings),
                const SizedBox(height: 24),
                _WidgetSection(settings: settings),
                const SizedBox(height: 24),
                _DataSection(),
                const SizedBox(height: 24),
                _AboutSection(),
                const SizedBox(height: 24),
                _AccountSection(),
              ],
            ),
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, stack) => Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    Icon(Icons.error_outline,
                        size: 48, color: Theme.of(context).colorScheme.error),
                    const SizedBox(height: 16),
                    Text('Error loading settings',
                        style: TextStyle(color: Theme.of(context).colorScheme.error)),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => ref.refresh(settingsProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeSection extends ConsumerWidget {
  final SettingsState settings;

  const _ThemeSection({required this.settings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeLabels = {
      AppThemeMode.light: 'Light',
      AppThemeMode.dark: 'Dark',
      AppThemeMode.system: 'System',
    };

    return _SettingsSection(
      title: 'Theme',
      icon: Icons.palette_outlined,
      child: Column(
        children: AppThemeMode.values.map((theme) {
          final isSelected = settings.themeMode == theme;
          return _SettingsTile(
            title: themeLabels[theme] ?? theme.name,
            trailing: isSelected
                ? Icon(Icons.check, color: context.primaryColor, size: 20)
                : null,
            onTap: () {
              ref.read(settingsProvider.notifier).setThemeMode(theme);
            },
          );
        }).toList(),
      ),
    );
  }
}

class _CurrencySection extends ConsumerWidget {
  final SettingsState settings;

  const _CurrencySection({required this.settings});

  String _getCurrencySymbol(String code) {
    final symbols = {
      'USD': '\$',
      'EUR': '€',
      'GBP': '£',
      'JPY': '¥',
      'CNY': '¥',
      'INR': '₹',
      'AUD': 'A\$',
      'CAD': 'C\$',
      'AED': 'د.إ',
      'SAR': 'ر.س',
      'ZAR': 'R',
      'BRL': 'R\$',
      'MXN': '\$',
      'KRW': '₩',
      'SGD': 'S\$',
      'HKD': 'HK\$',
      'CHF': 'CHF',
      'SEK': 'kr',
      'NOK': 'kr',
      'DKK': 'kr',
      'PLN': 'zł',
      'TRY': '₺',
      'RUB': '₽',
      'NZD': 'NZ\$',
    };
    return symbols[code] ?? code;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _SettingsSection(
      title: 'Currency',
      icon: Icons.attach_money_outlined,
      child: _CurrencyDropdown(
        selectedCurrency: settings.currency,
        onCurrencySelected: (currency) {
          ref.read(settingsProvider.notifier).setCurrency(currency);
        },
        getCurrencySymbol: _getCurrencySymbol,
      ),
    );
  }
}

class _CurrencyDropdown extends StatefulWidget {
  final Currency selectedCurrency;
  final Function(Currency) onCurrencySelected;
  final String Function(String) getCurrencySymbol;

  const _CurrencyDropdown({
    required this.selectedCurrency,
    required this.onCurrencySelected,
    required this.getCurrencySymbol,
  });

  @override
  State<_CurrencyDropdown> createState() => _CurrencyDropdownState();
}

class _CurrencyDropdownState extends State<_CurrencyDropdown> {
  void _showCurrencyPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CurrencyPickerBottomSheet(
        selectedCurrency: widget.selectedCurrency,
        onCurrencySelected: widget.onCurrencySelected,
        getCurrencySymbol: widget.getCurrencySymbol,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showCurrencyPicker(context),
      child: _SettingsTile(
        title: '${widget.getCurrencySymbol(widget.selectedCurrency.name)} ${widget.selectedCurrency.name}',
        trailing: const Icon(Icons.keyboard_arrow_down, size: 20),
      ),
    );
  }
}

class _CurrencyPickerBottomSheet extends StatefulWidget {
  final Currency selectedCurrency;
  final Function(Currency) onCurrencySelected;
  final String Function(String) getCurrencySymbol;

  const _CurrencyPickerBottomSheet({
    required this.selectedCurrency,
    required this.onCurrencySelected,
    required this.getCurrencySymbol,
  });

  @override
  State<_CurrencyPickerBottomSheet> createState() => _CurrencyPickerBottomSheetState();
}

class _CurrencyPickerBottomSheetState extends State<_CurrencyPickerBottomSheet> {
  late TextEditingController _searchController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredCurrencies = _searchQuery.isEmpty
        ? Currency.values
        : Currency.values
            .where((c) => c.name.toLowerCase().contains(_searchQuery))
            .toList();

    return Container(
      decoration: BoxDecoration(
        color: context.backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: context.borderColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Select Currency',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: context.onSurfaceColor,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search currency...',
                hintStyle: TextStyle(color: context.onSurfaceMutedColor),
                prefixIcon: Icon(Icons.search, size: 20, color: context.onSurfaceMutedColor),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, size: 20, color: context.onSurfaceMutedColor),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
                filled: true,
                fillColor: context.surfaceColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: context.primaryColor, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          Flexible(
            child: filteredCurrencies.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'No currencies found',
                      style: TextStyle(
                        color: context.onSurfaceMutedColor,
                        fontSize: 14,
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: filteredCurrencies.length,
                    itemBuilder: (context, index) {
                      final currency = filteredCurrencies[index];
                      final isSelected = widget.selectedCurrency == currency;
                      return InkWell(
                        onTap: () {
                          widget.onCurrencySelected(currency);
                          Navigator.of(context).pop();
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? context.primaryColor.withOpacity(0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border: isSelected
                                ? Border.all(
                                    color: context.primaryColor.withOpacity(0.3),
                                    width: 1,
                                  )
                                : null,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${widget.getCurrencySymbol(currency.name)} ${currency.name}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isSelected
                                        ? FontWeight.w500
                                        : FontWeight.w400,
                                    color: context.onSurfaceColor,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check,
                                  color: context.primaryColor,
                                  size: 20,
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
        ],
      ),
    );
  }
}

class _NamingFormatSection extends ConsumerWidget {
  final SettingsState settings;

  const _NamingFormatSection({required this.settings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formatLabels = {
      NamingFormat.storeDate: 'Store - Date',
      NamingFormat.dateStore: 'Date - Store',
      NamingFormat.storeOnly: 'Store Only',
      NamingFormat.dateOnly: 'Date Only',
    };

    return _SettingsSection(
      title: 'Receipt Naming Format',
      icon: Icons.text_fields_outlined,
      child: Column(
        children: NamingFormat.values.map((format) {
          final isSelected = settings.namingFormat == format;
          return _SettingsTile(
            title: formatLabels[format] ?? format.name,
            trailing: isSelected
                ? Icon(Icons.check, color: context.primaryColor, size: 20)
                : null,
            onTap: () {
              ref.read(settingsProvider.notifier).setNamingFormat(format);
            },
          );
        }).toList(),
      ),
    );
  }
}

class _WidgetSection extends ConsumerWidget {
  final SettingsState settings;

  const _WidgetSection({required this.settings});

  String _getStatLabel(WidgetStat stat) {
    switch (stat) {
      case WidgetStat.totalThisMonth:
        return 'Total This Month';
      case WidgetStat.topStore:
        return 'Top Store';
      case WidgetStat.receiptsCount:
        return 'Receipts Count';
      case WidgetStat.averagePerReceipt:
        return 'Average Per Receipt';
      case WidgetStat.daysWithExpenses:
        return 'Days with Expenses';
      case WidgetStat.totalItems:
        return 'Total Items';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _SettingsSection(
      title: 'Home Widget',
      icon: Icons.widgets_outlined,
      child: Column(
        children: [
          // Preview
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Preview',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: context.onSurfaceMutedColor,
                  ),
                ),
                const SizedBox(height: 8),
                WidgetPreview(
                  enabledStats: settings.widgetSettings.enabledStats,
                  currency: settings.currency,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Stat options
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Text(
                    'Display Stats',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: context.onSurfaceMutedColor,
                    ),
                  ),
                ),
                ...WidgetStat.values.map((stat) {
                  final isEnabled = settings.widgetSettings.enabledStats.contains(stat);
                  return InkWell(
                    onTap: () {
                      final currentStats = Set<WidgetStat>.from(
                        settings.widgetSettings.enabledStats,
                      );
                      if (isEnabled) {
                        currentStats.remove(stat);
                      } else {
                        currentStats.add(stat);
                      }
                      final updatedWidgetSettings = settings.widgetSettings.copyWith(
                        enabledStats: currentStats,
                      );
                      ref.read(settingsProvider.notifier).setWidgetSettings(
                        updatedWidgetSettings,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _getStatLabel(stat),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: context.onSurfaceColor,
                              ),
                            ),
                          ),
                          Checkbox(
                            value: isEnabled,
                            onChanged: (value) {
                              final currentStats = Set<WidgetStat>.from(
                                settings.widgetSettings.enabledStats,
                              );
                              if (value == true) {
                                currentStats.add(stat);
                              } else {
                                currentStats.remove(stat);
                              }
                              final updatedWidgetSettings = settings.widgetSettings.copyWith(
                                enabledStats: currentStats,
                              );
                              ref.read(settingsProvider.notifier).setWidgetSettings(
                                updatedWidgetSettings,
                              );
                            },
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DataSection extends ConsumerWidget {
  const _DataSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _SettingsSection(
      title: 'Data',
      icon: Icons.storage_outlined,
      child: Column(
        children: [
          _SettingsTile(
            title: 'Backup Data',
            subtitle: 'Export all receipts and settings',
            leading: Icons.backup_outlined,
            onTap: () => _backupData(context, ref),
          ),
          _SettingsTile(
            title: 'Restore Data',
            subtitle: 'Import receipts and settings from backup',
            leading: Icons.restore_outlined,
            onTap: () => _restoreData(context, ref),
          ),
          _SettingsTile(
            title: 'Export Data',
            subtitle: 'Export all receipts as JSON',
            leading: Icons.download_outlined,
            onTap: () => _exportData(context, ref),
          ),
          _SettingsTile(
            title: 'Clear All Data',
            subtitle: 'Delete all receipts and settings',
            leading: Icons.delete_outline,
            textColor: Theme.of(context).colorScheme.error,
            onTap: () => _showClearDataDialog(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _backupData(BuildContext context, WidgetRef ref) async {
    try {
      final receiptsAsync = ref.read(receiptsStoreProvider);
      final receipts = receiptsAsync.valueOrNull ?? [];
      final settingsAsync = ref.read(settingsProvider);
      final settings = settingsAsync.valueOrNull ?? SettingsState();

      final data = {
        'backupDate': DateTime.now().toIso8601String(),
        'version': '1.0.0',
        'settings': {
          'currency': settings.currency.name,
          'namingFormat': settings.namingFormat.name,
          'themeMode': settings.themeMode.name,
        },
        'receipts': receipts
            .map((r) => {
                  'id': r.id,
                  'name': r.name,
                  'date': r.date.toIso8601String(),
                  'store': r.store,
                  'total': r.total,
                  'items': r.items.map((i) => i.toJson()).toList(),
                })
            .toList(),
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(data);

      await Clipboard.setData(ClipboardData(text: jsonString));

      if (context.mounted) {
        final tempDir = await getTemporaryDirectory();
        final file = File(
            '${tempDir.path}/hisabi_backup_${DateTime.now().millisecondsSinceEpoch}.json');
        await file.writeAsString(jsonString);

        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Hisabi Backup',
        );
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Backup created and copied to clipboard'),
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup failed: $e'),
            backgroundColor: Theme.of(context).colorScheme.errorContainer,
          ),
        );
      }
    }
  }

  Future<void> _restoreData(BuildContext context, WidgetRef ref) async {
    try {
      final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
      if (clipboardData?.text == null || clipboardData!.text!.isEmpty) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'No data found in clipboard. Please copy a backup file first.'),
            ),
          );
        }
        return;
      }

      final data = jsonDecode(clipboardData.text!) as Map<String, dynamic>;

      if (data['settings'] != null) {
        final settingsData = data['settings'] as Map<String, dynamic>;
        final currency = Currency.values.firstWhere(
          (c) => c.name == settingsData['currency'],
          orElse: () => Currency.USD,
        );
        final namingFormat = NamingFormat.values.firstWhere(
          (f) => f.name == settingsData['namingFormat'],
          orElse: () => NamingFormat.storeDate,
        );
        final themeMode = AppThemeMode.values.firstWhere(
          (t) => t.name == settingsData['themeMode'],
          orElse: () => AppThemeMode.dark,
        );

        final settings = SettingsState(
          currency: currency,
          namingFormat: namingFormat,
          themeMode: themeMode,
        );
        await StorageService.saveSettings(settings);
        ref.invalidate(settingsProvider);
      }

      if (data['receipts'] != null) {
        final receiptsList = data['receipts'] as List;
        final receipts = receiptsList.map((json) {
          return ReceiptModel(
            id: json['id'] as String? ?? '',
            name: json['name'] as String? ?? '',
            date: DateTime.tryParse(json['date'] as String? ?? '') ??
                DateTime.now(),
            store: json['store'] as String? ?? '',
            items: (json['items'] as List?)
                    ?.map((item) => ReceiptItem(
                          name: item['name'] as String? ?? '',
                          quantity:
                              (item['quantity'] as num?)?.toDouble() ?? 0.0,
                          price: (item['price'] as num?)?.toDouble() ?? 0.0,
                          total: (item['total'] as num?)?.toDouble() ?? 0.0,
                        ))
                    .toList() ??
                [],
            total: (json['total'] as num?)?.toDouble() ?? 0.0,
          );
        }).toList();

        await StorageService.saveReceipts(receipts);
        ref.invalidate(receiptsStoreProvider);
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Data restored successfully'),
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Restore failed: $e'),
            backgroundColor: Theme.of(context).colorScheme.errorContainer,
          ),
        );
      }
    }
  }

  Future<void> _exportData(BuildContext context, WidgetRef ref) async {
    try {
      final receiptsAsync = ref.read(receiptsStoreProvider);
      final receipts = receiptsAsync.valueOrNull ?? [];

      if (receipts.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No data to export')),
        );
        return;
      }

      final data = {
        'exportDate': DateTime.now().toIso8601String(),
        'receipts': receipts
            .map((r) => {
                  'id': r.id,
                  'name': r.name,
                  'date': r.date.toIso8601String(),
                  'store': r.store,
                  'total': r.total,
                  'items': r.items.map((i) => i.toJson()).toList(),
                })
            .toList(),
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(data);

      // Copy to clipboard
      await Clipboard.setData(ClipboardData(text: jsonString));

      // Also try to share
      if (context.mounted) {
        final tempDir = await getTemporaryDirectory();
        final file = File(
            '${tempDir.path}/hisabi_export_${DateTime.now().millisecondsSinceEpoch}.json');
        await file.writeAsString(jsonString);

        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Hisabi Receipt Export',
        );
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Data exported and copied to clipboard'),
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Theme.of(context).colorScheme.errorContainer,
          ),
        );
      }
    }
  }

  Future<void> _showClearDataDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.surfaceColor,
        title: const Text('Clear All Data?'),
        content: const Text(
          'This will permanently delete all receipts and settings. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.errorContainer,
            ),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await StorageService.clearAll();
      ref.invalidate(receiptsStoreProvider);
      ref.invalidate(settingsProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('All data cleared'),
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          ),
        );
      }
    }
  }
}

class _AboutSection extends StatelessWidget {
  const _AboutSection();

  @override
  Widget build(BuildContext context) {
    return _SettingsSection(
      title: 'About',
      icon: Icons.info_outline,
      child: Column(
        children: [
          _SettingsTile(
            title: 'Version',
            subtitle: '1.0.0',
            leading: Icons.tag_outlined,
          ),
          _SettingsTile(
            title: 'Privacy Policy',
            leading: Icons.privacy_tip_outlined,
            onTap: () {
              context.push('/privacy-policy');
            },
          ),
          _SettingsTile(
            title: 'Terms of Service',
            leading: Icons.description_outlined,
            onTap: () {
              context.push('/terms-of-service');
            },
          ),
        ],
      ),
    );
  }
}

class _AccountSection extends ConsumerWidget {
  const _AccountSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _SettingsSection(
      title: 'Account',
      icon: Icons.person_outline,
      child: Column(
        children: [
          _SettingsTile(
            title: 'Financial Profile',
            subtitle: 'Manage your income and financial goals',
            leading: Icons.account_balance_wallet_outlined,
            trailing: Icon(Icons.chevron_right, size: 20, color: context.onSurfaceMutedColor),
            onTap: () {
              context.push('/financial-profile');
            },
          ),
          _SettingsTile(
            title: 'Logout',
            subtitle: 'Sign out of your account',
            leading: Icons.logout_outlined,
            textColor: Theme.of(context).colorScheme.error,
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: context.surfaceColor,
                  title: const Text('Logout?'),
                  content: const Text(
                    'Are you sure you want to logout?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.errorContainer,
                      ),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );

              if (confirmed == true && context.mounted) {
                await ref.read(authProvider.notifier).logout();
                if (context.mounted) {
                  context.go('/login');
                }
              }
            },
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _SettingsSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: context.primaryColor),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: context.onSurfaceColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: context.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: context.borderColor,
              width: 1,
            ),
          ),
          child: child,
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? textColor;

  const _SettingsTile({
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: context.borderColor.withOpacity(0.5),
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            if (leading != null) ...[
              Icon(
                leading,
                size: 20,
                color: textColor ?? context.onSurfaceMutedColor,
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: textColor ?? context.onSurfaceColor,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        color: context.onSurfaceMutedColor,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
