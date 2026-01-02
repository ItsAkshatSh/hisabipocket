import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisabi/core/constants/app_theme.dart';
import 'package:hisabi/core/storage/storage_service.dart';
import 'package:hisabi/features/receipts/providers/receipts_store.dart';
import 'package:hisabi/features/settings/providers/settings_provider.dart';
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
          const Text(
            'Settings',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              letterSpacing: -1.0,
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Manage your app preferences and data',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.onSurfaceMuted,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 32),

          // Settings Sections
          settingsAsync.when(
            data: (settings) => Column(
              children: [
                _CurrencySection(settings: settings),
                const SizedBox(height: 24),
                _NamingFormatSection(settings: settings),
                const SizedBox(height: 24),
                _DataSection(),
                const SizedBox(height: 24),
                _AboutSection(),
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
                    const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                    const SizedBox(height: 16),
                    Text('Error loading settings', style: const TextStyle(color: AppColors.error)),
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

class _CurrencySection extends ConsumerWidget {
  final SettingsState settings;

  const _CurrencySection({required this.settings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _SettingsSection(
      title: 'Currency',
      icon: Icons.attach_money_outlined,
      child: Column(
        children: Currency.values.map((currency) {
          final isSelected = settings.currency == currency;
          return _SettingsTile(
            title: currency.name,
            trailing: isSelected
                ? Icon(Icons.check, color: AppColors.primary, size: 20)
                : null,
            onTap: () {
              ref.read(settingsProvider.notifier).setCurrency(currency);
            },
          );
        }).toList(),
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
                ? Icon(Icons.check, color: AppColors.primary, size: 20)
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
            title: 'Export Data',
            subtitle: 'Export all receipts as JSON',
            leading: Icons.download_outlined,
            onTap: () => _exportData(context, ref),
          ),
          _SettingsTile(
            title: 'Clear All Data',
            subtitle: 'Delete all receipts and settings',
            leading: Icons.delete_outline,
            textColor: AppColors.error,
            onTap: () => _showClearDataDialog(context, ref),
          ),
        ],
      ),
    );
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
        'receipts': receipts.map((r) => {
          'id': r.id,
          'name': r.name,
          'date': r.date.toIso8601String(),
          'store': r.store,
          'total': r.total,
          'items': r.items.map((i) => i.toJson()).toList(),
        }).toList(),
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(data);
      
      // Copy to clipboard
      await Clipboard.setData(ClipboardData(text: jsonString));
      
      // Also try to share
      if (context.mounted) {
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/hisabi_export_${DateTime.now().millisecondsSinceEpoch}.json');
        await file.writeAsString(jsonString);
        
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Hisabi Receipt Export',
        );
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data exported and copied to clipboard'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _showClearDataDialog(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
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
              backgroundColor: AppColors.error,
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
          const SnackBar(
            content: Text('All data cleared'),
            backgroundColor: AppColors.success,
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
              // Navigate to privacy policy
            },
          ),
          _SettingsTile(
            title: 'Terms of Service',
            leading: Icons.description_outlined,
            onTap: () {
              // Navigate to terms
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
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.border,
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
              color: AppColors.border.withOpacity(0.5),
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
                color: textColor ?? AppColors.onSurfaceMuted,
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
                      color: textColor ?? AppColors.onSurface,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.onSurfaceMuted,
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

