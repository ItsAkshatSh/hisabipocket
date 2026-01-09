import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hisabi/core/utils/theme_extensions.dart';
import 'package:hisabi/features/financial_profile/providers/financial_profile_provider.dart';
import 'package:hisabi/features/financial_profile/models/financial_profile_model.dart';
import 'package:hisabi/features/financial_profile/presentation/widgets/recurring_payments_section.dart';
import 'package:hisabi/features/settings/providers/settings_provider.dart';

class FinancialProfileScreen extends ConsumerStatefulWidget {
  const FinancialProfileScreen({super.key});

  @override
  ConsumerState<FinancialProfileScreen> createState() =>
      _FinancialProfileScreenState();
}

class _FinancialProfileScreenState
    extends ConsumerState<FinancialProfileScreen> {
  late TextEditingController _incomeController;
  late TextEditingController _savingsGoalController;
  bool _incomeInitialized = false;
  bool _savingsInitialized = false;

  @override
  void initState() {
    super.initState();
    _incomeController = TextEditingController();
    _savingsGoalController = TextEditingController();
  }

  @override
  void dispose() {
    _incomeController.dispose();
    _savingsGoalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(financialProfileProvider);
    final settingsAsync = ref.watch(settingsProvider);
    final currency = settingsAsync.valueOrNull?.currency ?? Currency.USD;
    final isMobile = MediaQuery.of(context).size.width < 600;

    // Sync currency from settings to profile when settings change
    final profile = profileAsync.valueOrNull;
    if (profile != null && profile.currency != currency) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(financialProfileProvider.notifier).syncCurrencyFromSettings();
      });
    }

    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
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
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => context.go('/dashboard'),
                    color: context.onSurfaceColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Financial Profile',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -1.0,
                            color: context.onSurfaceColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Help us provide better insights and recommendations',
                          style: TextStyle(
                            fontSize: 14,
                            color: context.onSurfaceMutedColor,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              profileAsync.when(
                data: (profile) {
                  // Initialize controllers with current values only once
                  if (!_incomeInitialized) {
                    if (profile.monthlyIncome != null) {
                      _incomeController.text =
                          profile.monthlyIncome!.toStringAsFixed(0);
                    }
                    _incomeInitialized = true;
                  }
                  if (!_savingsInitialized) {
                    if (profile.savingsGoalPercentage != null) {
                      _savingsGoalController.text =
                          profile.savingsGoalPercentage!.toStringAsFixed(1);
                    }
                    _savingsInitialized = true;
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Monthly Income Section
                      _ProfileSection(
                        title: 'Monthly Income',
                        icon: Icons.account_balance_wallet_outlined,
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: TextField(
                                controller: _incomeController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                style: TextStyle(
                                  fontSize: 16,
                                  color: context.onSurfaceColor,
                                ),
                                decoration: InputDecoration(
                                  labelText: 'Monthly Income',
                                  hintText: 'Enter your monthly income',
                                  prefixText: '${currency.name} ',
                                  prefixStyle: TextStyle(
                                    color: context.onSurfaceMutedColor,
                                  ),
                                  suffixIcon: _incomeController.text.isNotEmpty
                                      ? IconButton(
                                          icon: Icon(
                                            Icons.clear,
                                            size: 20,
                                            color: context.onSurfaceMutedColor,
                                          ),
                                          onPressed: () {
                                            _incomeController.clear();
                                            _saveIncome(null);
                                          },
                                        )
                                      : null,
                                  filled: true,
                                  fillColor: context.surfaceColor,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: context.borderColor,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: context.borderColor,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: context.primaryColor,
                                      width: 2,
                                    ),
                                  ),
                                  labelStyle: TextStyle(
                                    color: context.onSurfaceMutedColor,
                                  ),
                                  hintStyle: TextStyle(
                                    color: context.onSurfaceMutedColor,
                                  ),
                                ),
                                onChanged: (value) {
                                  if (value.isNotEmpty) {
                                    final income = double.tryParse(value);
                                    if (income != null && income > 0) {
                                      _saveIncome(income);
                                    }
                                  } else {
                                    _saveIncome(null);
                                  }
                                },
                              ),
                            ),
                            if (profile.monthlyIncome != null) ...[
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 16.0,
                                  right: 16.0,
                                  bottom: 16.0,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: context.primaryColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        size: 16,
                                        color: context.primaryColor,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'This helps us provide accurate budget recommendations',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: context.primaryColor,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Savings Goal Section
                      _ProfileSection(
                        title: 'Savings Goal',
                        icon: Icons.savings_outlined,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: TextField(
                            controller: _savingsGoalController,
                            keyboardType:
                                TextInputType.numberWithOptions(decimal: true),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d+\.?\d{0,2}'),
                              ),
                            ],
                            style: TextStyle(
                              fontSize: 16,
                              color: context.onSurfaceColor,
                            ),
                            decoration: InputDecoration(
                              labelText: 'Target Savings Rate',
                              hintText: 'e.g., 20',
                              suffixText: '%',
                              filled: true,
                              fillColor: context.surfaceColor,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: context.borderColor,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: context.borderColor,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: context.primaryColor,
                                  width: 2,
                                ),
                              ),
                              labelStyle: TextStyle(
                                color: context.onSurfaceMutedColor,
                              ),
                              hintStyle: TextStyle(
                                color: context.onSurfaceMutedColor,
                              ),
                            ),
                            onChanged: (value) {
                              if (value.isNotEmpty) {
                                final percentage = double.tryParse(value);
                                if (percentage != null &&
                                    percentage >= 0 &&
                                    percentage <= 100) {
                                  _saveSavingsGoal(percentage);
                                }
                              } else {
                                _saveSavingsGoal(null);
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Employment Status Section
                      _ProfileSection(
                        title: 'Employment Status',
                        icon: Icons.work_outline,
                        child: Column(
                          children: EmploymentStatus.values.map((status) {
                            final isSelected =
                                profile.employmentStatus == status;
                            return _SettingsTile(
                              title: _getEmploymentStatusLabel(status),
                              trailing: isSelected
                                  ? Icon(
                                      Icons.check,
                                      color: context.primaryColor,
                                      size: 20,
                                    )
                                  : null,
                              onTap: () {
                                ref
                                    .read(financialProfileProvider.notifier)
                                    .setEmploymentStatus(status);
                              },
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Recurring Payments Section
                      RecurringPaymentsSection(
                        payments: profile.recurringPayments,
                      ),
                      const SizedBox(height: 24),

                      // Completion Status
                      if (!profile.isComplete)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.orange.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.orange,
                                size: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Complete your profile to get personalized insights',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.orange.shade700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, stack) => Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading profile',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () =>
                            ref.refresh(financialProfileProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveIncome(double? income) {
    if (income != null) {
      ref.read(financialProfileProvider.notifier).setMonthlyIncome(income);
    } else {
      final currentProfile =
          ref.read(financialProfileProvider).valueOrNull ?? FinancialProfile();
      ref.read(financialProfileProvider.notifier).updateProfile(
            currentProfile.copyWith(monthlyIncome: null),
          );
    }
  }

  void _saveSavingsGoal(double? percentage) {
    if (percentage != null) {
      ref.read(financialProfileProvider.notifier).setSavingsGoal(percentage);
    } else {
      final currentProfile =
          ref.read(financialProfileProvider).valueOrNull ?? FinancialProfile();
      ref.read(financialProfileProvider.notifier).updateProfile(
            currentProfile.copyWith(savingsGoalPercentage: null),
          );
    }
  }

  String _getEmploymentStatusLabel(EmploymentStatus status) {
    switch (status) {
      case EmploymentStatus.student:
        return 'Student';
      case EmploymentStatus.employed:
        return 'Employed';
      case EmploymentStatus.freelancer:
        return 'Freelancer';
      case EmploymentStatus.retired:
        return 'Retired';
      case EmploymentStatus.other:
        return 'Other';
    }
  }
}

class _ProfileSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _ProfileSection({
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
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.title,
    this.trailing,
    this.onTap,
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
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: context.onSurfaceColor,
                ),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

