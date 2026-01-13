import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hisabi/features/settings/providers/settings_provider.dart';
import 'package:hisabi/features/auth/providers/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SliverAppBar.large(
            title: Text('Settings'),
            centerTitle: false,
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: settingsAsync.when(
              data: (settings) => SliverList(
                delegate: SliverChildListDelegate([
                  _buildSectionHeader(context, 'Appearance'),
                  const SizedBox(height: 12),
                  _buildThemeCard(context, ref, settings),
                  const SizedBox(height: 24),
                  _buildSectionHeader(context, 'Preferences'),
                  const SizedBox(height: 12),
                  _buildPreferenceCard(context, ref, settings),
                  const SizedBox(height: 24),
                  _buildSectionHeader(context, 'Account'),
                  const SizedBox(height: 12),
                  _buildAccountCard(context, ref),
                  const SizedBox(height: 100),
                ]),
              ),
              loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
              error: (err, stack) => SliverFillRemaining(child: Center(child: Text('Error loading settings'))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w900,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: -0.5,
        ),
      ),
    );
  }

  Widget _buildThemeCard(BuildContext context, WidgetRef ref, SettingsState settings) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Theme Palette', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(settings.themeSelection.name.toUpperCase()),
            onTap: () => _showThemePicker(context, ref, settings.themeSelection),
          ),
          const Divider(indent: 56),
          ListTile(
            leading: const Icon(Icons.brightness_medium_outlined),
            title: const Text('Theme Mode', style: TextStyle(fontWeight: FontWeight.bold)),
            trailing: SegmentedButton<AppThemeMode>(
              segments: const [
                ButtonSegment(value: AppThemeMode.light, icon: Icon(Icons.light_mode_outlined)),
                ButtonSegment(value: AppThemeMode.dark, icon: Icon(Icons.dark_mode_outlined)),
                ButtonSegment(value: AppThemeMode.system, icon: Icon(Icons.settings_brightness_outlined)),
              ],
              selected: {settings.themeMode},
              onSelectionChanged: (value) => ref.read(settingsProvider.notifier).setThemeMode(value.first),
              showSelectedIcon: false,
              style: SegmentedButton.styleFrom(visualDensity: VisualDensity.compact),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  Widget _buildPreferenceCard(BuildContext context, WidgetRef ref, SettingsState settings) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.attach_money_outlined),
            title: const Text('Currency', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(settings.currency.name),
            onTap: () => _showCurrencyPicker(context, ref, settings.currency),
          ),
          const Divider(indent: 56),
          ListTile(
            leading: const Icon(Icons.label_outlined),
            title: const Text('Receipt Naming', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(settings.namingFormat.name.replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m[0]}').toUpperCase()),
            onTap: () => _showNamingFormatPicker(context, ref, settings.namingFormat),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1);
  }

  Widget _buildAccountCard(BuildContext context, WidgetRef ref) {
    return Card(
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.account_balance_wallet_outlined),
            title: const Text('Financial Profile', style: TextStyle(fontWeight: FontWeight.bold)),
            onTap: () => context.push('/financial-profile'),
          ),
          const Divider(indent: 56),
          ListTile(
            leading: const Icon(Icons.logout_outlined, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            onTap: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1);
  }

  void _showThemePicker(BuildContext context, WidgetRef ref, AppThemeSelection current) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) => Container(
        padding: const EdgeInsets.only(bottom: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: AppThemeSelection.values.map((selection) => ListTile(
            title: Text(selection.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
            leading: Container(width: 24, height: 24, decoration: BoxDecoration(shape: BoxShape.circle, color: _getThemeColor(selection))),
            selected: selection == current,
            onTap: () {
              ref.read(settingsProvider.notifier).setThemeSelection(selection);
              Navigator.pop(context);
            },
          )).toList(),
        ),
      ),
    );
  }

  Color _getThemeColor(AppThemeSelection selection) {
    switch (selection) {
      case AppThemeSelection.classic: return const Color(0xFF6366F1);
      case AppThemeSelection.midnight: return const Color(0xFF1E293B);
      case AppThemeSelection.forest: return const Color(0xFF064E3B);
      case AppThemeSelection.sunset: return const Color(0xFF7C2D12);
      case AppThemeSelection.lavender: return const Color(0xFF4C1D95);
      case AppThemeSelection.monochrome: return Colors.blueGrey;
    }
  }

  void _showCurrencyPicker(BuildContext context, WidgetRef ref, Currency current) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) => ListView.builder(
        itemCount: Currency.values.length,
        itemBuilder: (context, index) {
          final currency = Currency.values[index];
          return ListTile(
            title: Text(currency.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            selected: currency == current,
            onTap: () {
              ref.read(settingsProvider.notifier).setCurrency(currency);
              Navigator.pop(context);
            },
          );
        },
      ),
    );
  }

  void _showNamingFormatPicker(BuildContext context, WidgetRef ref, NamingFormat current) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: NamingFormat.values.map((f) => ListTile(
          title: Text(f.name.replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m[0]}').toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold)),
          selected: f == current,
          onTap: () {
            ref.read(settingsProvider.notifier).setNamingFormat(f);
            Navigator.pop(context);
          },
        )).toList(),
      ),
    );
  }
}
