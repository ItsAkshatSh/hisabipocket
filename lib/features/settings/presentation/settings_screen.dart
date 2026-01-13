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
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            sliver: settingsAsync.when(
              data: (settings) => SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 12),
                  _buildSectionHeader(context, 'Appearance'),
                  const SizedBox(height: 16),
                  _buildThemeCard(context, ref, settings),
                  const SizedBox(height: 32),
                  _buildSectionHeader(context, 'Preferences'),
                  const SizedBox(height: 16),
                  _buildPreferenceCard(context, ref, settings),
                  const SizedBox(height: 32),
                  _buildSectionHeader(context, 'Account'),
                  const SizedBox(height: 16),
                  _buildAccountCard(context, ref),
                  const SizedBox(height: 120),
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
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w900,
        color: Theme.of(context).colorScheme.primary,
        letterSpacing: 1.2,
      ),
    ).animate().fadeIn().slideX(begin: -0.1);
  }

  Widget _buildThemeCard(BuildContext context, WidgetRef ref, SettingsState settings) {
    return _SettingsCard(
      children: [
        _SettingsTile(
          icon: Icons.palette_outlined,
          title: 'Theme Palette',
          subtitle: settings.themeSelection.name.toUpperCase(),
          onTap: () => _showThemePicker(context, ref, settings.themeSelection),
        ),
        const Divider(height: 1),
        _SettingsTile(
          icon: Icons.brightness_medium_outlined,
          title: 'Theme Mode',
          trailing: SegmentedButton<AppThemeMode>(
            segments: const [
              ButtonSegment(value: AppThemeMode.light, icon: Icon(Icons.light_mode_outlined, size: 20)),
              ButtonSegment(value: AppThemeMode.dark, icon: Icon(Icons.dark_mode_outlined, size: 20)),
              ButtonSegment(value: AppThemeMode.system, icon: Icon(Icons.settings_brightness_outlined, size: 20)),
            ],
            selected: {settings.themeMode},
            onSelectionChanged: (value) => ref.read(settingsProvider.notifier).setThemeMode(value.first),
            showSelectedIcon: false,
            style: SegmentedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
            ),
          ),
        ),
      ],
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  Widget _buildPreferenceCard(BuildContext context, WidgetRef ref, SettingsState settings) {
    return _SettingsCard(
      children: [
        _SettingsTile(
          icon: Icons.attach_money_outlined,
          title: 'Currency',
          subtitle: settings.currency.name,
          onTap: () => _showCurrencyPicker(context, ref, settings.currency),
        ),
        const Divider(height: 1),
        _SettingsTile(
          icon: Icons.label_outlined,
          title: 'Receipt Naming',
          subtitle: settings.namingFormat.name.replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m[0]}').toUpperCase(),
          onTap: () => _showNamingFormatPicker(context, ref, settings.namingFormat),
        ),
      ],
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1);
  }

  Widget _buildAccountCard(BuildContext context, WidgetRef ref) {
    return _SettingsCard(
      children: [
        _SettingsTile(
          icon: Icons.account_balance_wallet_outlined,
          title: 'Financial Profile',
          onTap: () => context.push('/financial-profile'),
        ),
        const Divider(height: 1),
        _SettingsTile(
          icon: Icons.logout_outlined,
          title: 'Logout',
          titleColor: Colors.red,
          iconColor: Colors.red,
          onTap: () async {
            await ref.read(authProvider.notifier).logout();
            if (context.mounted) context.go('/login');
          },
        ),
      ],
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
            title: Text(selection.name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
            leading: Container(
              width: 24, 
              height: 24, 
              decoration: BoxDecoration(
                shape: BoxShape.circle, 
                color: _getThemeColor(selection),
                border: Border.all(color: Colors.white24, width: 2),
              )
            ),
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
        shrinkWrap: true,
        itemCount: Currency.values.length,
        itemBuilder: (context, index) {
          final currency = Currency.values[index];
          return ListTile(
            title: Text(currency.name, style: const TextStyle(fontWeight: FontWeight.w800)),
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
          title: Text(f.name.replaceAllMapped(RegExp(r'([A-Z])'), (m) => ' ${m[0]}').toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w800)),
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

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.3),
        ),
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? titleColor;
  final Color? iconColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.titleColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: (iconColor ?? Theme.of(context).colorScheme.primary).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor ?? Theme.of(context).colorScheme.primary, size: 22),
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: titleColor)),
      subtitle: subtitle != null ? Text(subtitle!, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant)) : null,
      trailing: trailing ?? (onTap != null ? const Icon(Icons.chevron_right_rounded, size: 20) : null),
      onTap: onTap,
    );
  }
}
