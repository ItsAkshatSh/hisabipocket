import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisabi/core/storage/storage_service.dart';
import 'package:hisabi/features/financial_profile/models/financial_profile_model.dart';
import 'package:hisabi/features/financial_profile/models/recurring_payment_model.dart';
import 'package:hisabi/features/settings/providers/settings_provider.dart';
import 'package:hisabi/features/auth/providers/auth_provider.dart';

final financialProfileProvider =
    StateNotifierProvider.autoDispose<FinancialProfileNotifier, AsyncValue<FinancialProfile>>((ref) {
  final authState = ref.watch(authProvider);
  final notifier = FinancialProfileNotifier(ref);
  
  if (authState.status == AuthStatus.authenticated && authState.user != null) {
    notifier.loadProfile();
  }
  
  ref.listen<AuthState>(authProvider, (previous, next) {
    if (previous?.user?.email != next.user?.email) {
      notifier.loadProfile();
    }
  });
  
  return notifier;
});

class FinancialProfileNotifier extends StateNotifier<AsyncValue<FinancialProfile>> {
  final Ref _ref;
  
  FinancialProfileNotifier(this._ref) : super(const AsyncValue.loading());

  Future<void> loadProfile() async {
    state = const AsyncValue.loading();
    try {
      final profile = await StorageService.loadFinancialProfile();
      // Sync currency from settings if not set
      final settingsAsync = _ref.read(settingsProvider);
      final currency = settingsAsync.valueOrNull?.currency;
      final updatedProfile = profile.currency == null && currency != null
          ? profile.copyWith(currency: currency)
          : profile;
      state = AsyncValue.data(updatedProfile);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> updateProfile(FinancialProfile profile) async {
    final updatedProfile = profile.copyWith(lastUpdated: DateTime.now());
    state = AsyncValue.data(updatedProfile);

    try {
      await StorageService.saveFinancialProfile(updatedProfile);
    } catch (e) {
      await loadProfile();
      rethrow;
    }
  }

  Future<void> setMonthlyIncome(double income) async {
    final currentProfile = state.valueOrNull ?? FinancialProfile();
    final updatedProfile = currentProfile.copyWith(monthlyIncome: income);
    await updateProfile(updatedProfile);
  }

  Future<void> setSavingsGoal(double percentage) async {
    final currentProfile = state.valueOrNull ?? FinancialProfile();
    final updatedProfile = currentProfile.copyWith(savingsGoalPercentage: percentage);
    await updateProfile(updatedProfile);
  }

  Future<void> setEmploymentStatus(EmploymentStatus status) async {
    final currentProfile = state.valueOrNull ?? FinancialProfile();
    final updatedProfile = currentProfile.copyWith(employmentStatus: status);
    await updateProfile(updatedProfile);
  }

  Future<void> setFamilySize(int size) async {
    final currentProfile = state.valueOrNull ?? FinancialProfile();
    final updatedProfile = currentProfile.copyWith(familySize: size);
    await updateProfile(updatedProfile);
  }

  Future<void> setPrimaryPriority(FinancialPriority priority) async {
    final currentProfile = state.valueOrNull ?? FinancialProfile();
    final updatedProfile = currentProfile.copyWith(primaryPriority: priority);
    await updateProfile(updatedProfile);
  }

  Future<void> addRecurringPayment(RecurringPayment payment) async {
    final currentProfile = state.valueOrNull ?? FinancialProfile();
    final updatedPayments = [...currentProfile.recurringPayments, payment];
    final updatedProfile = currentProfile.copyWith(
      recurringPayments: updatedPayments,
    );
    await updateProfile(updatedProfile);
  }

  Future<void> removeRecurringPayment(String paymentId) async {
    final currentProfile = state.valueOrNull ?? FinancialProfile();
    final updatedPayments = currentProfile.recurringPayments
        .where((p) => p.id != paymentId)
        .toList();
    final updatedProfile = currentProfile.copyWith(
      recurringPayments: updatedPayments,
    );
    await updateProfile(updatedProfile);
  }

  Future<void> updateRecurringPayment(RecurringPayment payment) async {
    final currentProfile = state.valueOrNull ?? FinancialProfile();
    final updatedPayments = currentProfile.recurringPayments
        .map((p) => p.id == payment.id ? payment : p)
        .toList();
    final updatedProfile = currentProfile.copyWith(
      recurringPayments: updatedPayments,
    );
    await updateProfile(updatedProfile);
  }

  Future<void> syncCurrencyFromSettings() async {
    final settingsAsync = _ref.read(settingsProvider);
    final currency = settingsAsync.valueOrNull?.currency;
    if (currency != null) {
      final currentProfile = state.valueOrNull ?? FinancialProfile();
      final updatedProfile = currentProfile.copyWith(currency: currency);
      await updateProfile(updatedProfile);
    }
  }
}

