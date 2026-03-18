import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hisabi/core/widgets/app_bottom_sheet.dart';
import 'package:hisabi/core/services/onboarding_service.dart';
import 'package:hisabi/core/services/quick_start_service.dart';
import 'package:hisabi/features/settings/providers/settings_provider.dart';
import 'package:hisabi/features/auth/providers/auth_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            title: const Text('Settings'),
            centerTitle: false,
            actions: [
              if (user?.pictureUrl != null)
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: CircleAvatar(
                    backgroundImage: NetworkImage(user!.pictureUrl!),
                    radius: 18,
                  ),
                )
              else if (user != null)
                Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: CircleAvatar(
                    backgroundColor: cs.primaryContainer,
                    radius: 18,
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                      style: TextStyle(
                        color: cs.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            sliver: settingsAsync.when(
              data: (settings) => SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 12),
                  if (user != null) ...[
                    _buildProfileCard(context, user),
                    const SizedBox(height: 24),
                  ],
                  _buildSectionHeader(context, 'Appearance'),
                  const SizedBox(height: 16),
                  _buildThemeCard(context, ref, settings),
                  const SizedBox(height: 32),
                  _buildSectionHeader(context, 'Preferences'),
                  const SizedBox(height: 16),
                  _buildPreferenceCard(context, ref, settings),
                  const SizedBox(height: 32),
                  _buildSectionHeader(context, 'Widgets'),
                  const SizedBox(height: 16),
                  _buildWidgetCard(context, ref, settings),
                  const SizedBox(height: 32),
                  _buildSectionHeader(context, 'Money'),
                  const SizedBox(height: 16),
                  _buildBudgetCard(context, ref),
                  const SizedBox(height: 32),
                  _buildSectionHeader(context, 'Categorization'),
                  const SizedBox(height: 16),
                  _buildCategorizationCard(context, ref),
                  const SizedBox(height: 32),
                  _buildSectionHeader(context, 'Data'),
                  const SizedBox(height: 16),
                  _buildDataCard(context, ref),
                  const SizedBox(height: 32),
                  _buildSectionHeader(context, 'Legal'),
                  const SizedBox(height: 16),
                  _buildLegalCard(context),
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
    final cs = Theme.of(context).colorScheme;
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w800,
        color: cs.onSurfaceVariant,
        letterSpacing: 0.6,
      ),
    ).animate().fadeIn().slideX(begin: -0.1);
  }

  Widget _buildProfileCard(BuildContext context, dynamic user) {
    final cs = Theme.of(context).colorScheme;
    final displayName = (user.name as String?)?.trim();
    final initial = (displayName?.isNotEmpty ?? false) ? displayName![0].toUpperCase() : 'U';
    final email = (user.email as String?)?.trim();

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.3)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: CircleAvatar(
          backgroundColor: cs.primaryContainer,
          foregroundColor: cs.onPrimaryContainer,
          child: Text(initial, style: const TextStyle(fontWeight: FontWeight.w900)),
        ),
        title: Text(
          (displayName?.isNotEmpty ?? false) ? displayName! : 'Account',
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: email != null && email.isNotEmpty
            ? Text(email, style: TextStyle(color: cs.onSurfaceVariant, fontWeight: FontWeight.w600))
            : null,
        trailing: Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
        onTap: () => context.push('/financial-profile'),
      ),
    ).animate().fadeIn().slideY(begin: 0.05);
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
        const Divider(height: 1),
        _SettingsTile(
          icon: Icons.help_outline,
          title: 'Help & Tips',
          subtitle: 'Learn how to get the most from Hisabi',
          onTap: () => context.push('/help'),
        ),
        const Divider(height: 1),
        _SettingsTile(
          icon: Icons.school_outlined,
          title: 'Take the tour again',
          subtitle: 'Replay the quick Hisabi walkthrough',
          onTap: () async {
            await OnboardingService.resetOnboarding();
            await QuickStartService.resetQuickStart();
            if (context.mounted) context.push('/onboarding');
          },
        ),
      ],
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1);
  }

  Widget _buildWidgetCard(BuildContext context, WidgetRef ref, SettingsState settings) {
    final enabledCount = settings.widgetSettings.enabledStats.length;
    return _SettingsCard(
      children: [
        _SettingsTile(
          icon: Icons.widgets_outlined,
          title: 'Widget Settings',
          subtitle: '$enabledCount ${enabledCount == 1 ? 'stat' : 'stats'} enabled',
          onTap: () => context.push('/widget-settings'),
        ),
      ],
    ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1);
  }

  Widget _buildBudgetCard(BuildContext context, WidgetRef ref) {
    return _SettingsCard(
      children: [
        _SettingsTile(
          icon: Icons.account_balance_wallet_outlined,
          title: 'Budget Overview',
          subtitle: 'View and manage your budget',
          onTap: () => context.push('/budget-overview'),
        ),
        const Divider(height: 1),
        _SettingsTile(
          icon: Icons.edit_outlined,
          title: 'Set Budget',
          subtitle: 'Configure monthly budget',
          onTap: () => context.push('/budget-setup'),
        ),
        const Divider(height: 1),
        _SettingsTile(
          icon: Icons.savings_outlined,
          title: 'Savings Goals',
          subtitle: 'Track what you’re working toward',
          onTap: () => context.push('/savings-goals'),
        ),
        const Divider(height: 1),
        _SettingsTile(
          icon: Icons.receipt_long_outlined,
          title: 'Recurring Bills',
          subtitle: 'See upcoming bills and due dates',
          onTap: () => context.push('/recurring-bills'),
        ),
        const Divider(height: 1),
        _SettingsTile(
          icon: Icons.account_circle_outlined,
          title: 'Financial Profile',
          subtitle: 'Income, goals, and budget style',
          onTap: () => context.push('/financial-profile'),
        ),
      ],
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1);
  }

  Widget _buildCategorizationCard(BuildContext context, WidgetRef ref) {
    return _SettingsCard(
      children: [
        _SettingsTile(
          icon: Icons.rule_outlined,
          title: 'Categorization Rules',
          subtitle: 'Auto-categorize receipts',
          onTap: () => context.push('/categorization-rules'),
        ),
      ],
    ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.1);
  }

  Widget _buildDataCard(BuildContext context, WidgetRef ref) {
    return _SettingsCard(
      children: [
        _SettingsTile(
          icon: Icons.download_outlined,
          title: 'Export Data',
          subtitle: 'Export receipts to CSV or PDF',
          onTap: () => context.push('/export'),
        ),
      ],
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1);
  }

  Widget _buildAccountCard(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    return _SettingsCard(
      children: [
        _SettingsTile(
          icon: Icons.logout_outlined,
          title: 'Logout',
          titleColor: cs.error,
          iconColor: cs.error,
          onTap: () async {
            await ref.read(authProvider.notifier).logout();
            if (context.mounted) context.go('/login');
          },
        ),
      ],
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1);
  }

  Widget _buildLegalCard(BuildContext context) {
    return _SettingsCard(
      children: [
        _SettingsTile(
          icon: Icons.verified_user_outlined,
          title: 'Privacy Policy',
          subtitle: 'How we handle your data',
          onTap: () => context.push('/privacy-policy'),
        ),
        const Divider(height: 1),
        _SettingsTile(
          icon: Icons.description_outlined,
          title: 'Terms of Service',
          subtitle: 'The rules for using Hisabi',
          onTap: () => context.push('/terms-of-service'),
        ),
      ],
    ).animate().fadeIn(delay: 320.ms).slideY(begin: 0.1);
  }

  void _showThemePicker(BuildContext context, WidgetRef ref, AppThemeSelection current) {
    showAppBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Container(
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
                  border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.6), width: 2),
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
      ),
    );
  }

  Color _getThemeColor(AppThemeSelection selection) {
    switch (selection) {
      case AppThemeSelection.classic: return Colors.grey.shade700;
      case AppThemeSelection.midnight: return const Color(0xFF1E293B);
      case AppThemeSelection.forest: return const Color(0xFF064E3B);
      case AppThemeSelection.sunset: return const Color(0xFF7C2D12);
      case AppThemeSelection.lavender: return const Color(0xFF4C1D95);
      case AppThemeSelection.monochrome: return Colors.blueGrey;
    }
  }

  void _showCurrencyPicker(BuildContext context, WidgetRef ref, Currency current) {
    showAppBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: ListView.builder(
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
      ),
    );
  }

  void _showNamingFormatPicker(BuildContext context, WidgetRef ref, NamingFormat current) {
    showAppBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
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
