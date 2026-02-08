import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisabi/core/utils/theme_extensions.dart';
import 'package:hisabi/features/financial_profile/models/recurring_payment_model.dart';
import 'package:hisabi/features/financial_profile/providers/financial_profile_provider.dart';
import 'package:hisabi/features/settings/providers/settings_provider.dart';
import 'package:intl/intl.dart';

class AddRecurringPaymentModal extends ConsumerStatefulWidget {
  const AddRecurringPaymentModal({super.key});

  @override
  ConsumerState<AddRecurringPaymentModal> createState() =>
      _AddRecurringPaymentModalState();
}

class _AddRecurringPaymentModalState
    extends ConsumerState<AddRecurringPaymentModal> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(() {});
    _searchController.dispose();
    super.dispose();
  }

  void _handlePresetSelected(RecurringPaymentPreset preset) {
    _showPaymentDialog(preset: preset);
  }

  void _showCustomForm() {
    _showPaymentDialog();
  }

  void _showPaymentDialog({RecurringPaymentPreset? preset}) {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    var frequency = preset?.defaultFrequency ?? PaymentFrequency.monthly;
    var startDate = DateTime.now();
    
    if (preset != null) {
      nameController.text = preset.name;
    } else if (_searchController.text.isNotEmpty) {
      nameController.text = _searchController.text;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => _PaymentFormDialog(
        preset: preset,
        nameController: nameController,
        amountController: amountController,
        initialFrequency: frequency,
        initialStartDate: startDate,
        onSave: (payment) async {
          await ref.read(financialProfileProvider.notifier).addRecurringPayment(payment);
          if (mounted) {
            Navigator.of(dialogContext).pop();
            Navigator.of(context).pop(); 
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${payment.name} added successfully'),
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              ),
            );
          }
        },
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final filteredPresets = _searchQuery.isEmpty
        ? recurringPaymentPresets
        : recurringPaymentPresets
            .where((p) => p.name.toLowerCase().contains(_searchQuery))
            .toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: context.backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Add Recurring Payment',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: context.onSurfaceColor,
                  ),
                ),
              ],
            ),
          ),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search or create a recurring payment...',
                  hintStyle: TextStyle(color: context.onSurfaceMutedColor),
                  prefixIcon: Icon(
                    Icons.search,
                    color: context.onSurfaceMutedColor,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(
                            Icons.clear,
                            color: context.onSurfaceMutedColor,
                          ),
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
                    borderSide: BorderSide(
                      color: context.primaryColor,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 16),
          Expanded(
            child: _buildPresetList(context, filteredPresets),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetList(
      BuildContext context, List<RecurringPaymentPreset> presets) {
    final hasSearchQuery = _searchQuery.isNotEmpty;
    final hasMatchingPresets = presets.isNotEmpty;
    final showCreateButton = hasSearchQuery && !hasMatchingPresets;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        if (_searchQuery.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'Popular Services',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: context.onSurfaceMutedColor,
              ),
            ),
          ),
        ...presets.map((preset) => _PresetCard(
              preset: preset,
              isSelected: false,
              onTap: () => _handlePresetSelected(preset),
            )),
        if (showCreateButton) ...[
          const SizedBox(height: 8),
          _CreateCustomCard(
            searchText: _searchController.text,
            onTap: _showCustomForm,
          ),
        ],
        SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
      ],
    );
  }

}

class _PaymentFormDialog extends ConsumerStatefulWidget {
  final RecurringPaymentPreset? preset;
  final TextEditingController nameController;
  final TextEditingController amountController;
  final PaymentFrequency initialFrequency;
  final DateTime initialStartDate;
  final Function(RecurringPayment) onSave;

  const _PaymentFormDialog({
    this.preset,
    required this.nameController,
    required this.amountController,
    required this.initialFrequency,
    required this.initialStartDate,
    required this.onSave,
  });

  @override
  ConsumerState<_PaymentFormDialog> createState() => _PaymentFormDialogState();
}

class _PaymentFormDialogState extends ConsumerState<_PaymentFormDialog> {
  late PaymentFrequency _selectedFrequency;
  late DateTime _startDate;

  @override
  void initState() {
    super.initState();
    _selectedFrequency = widget.initialFrequency;
    _startDate = widget.initialStartDate;
  }

  Future<void> _savePayment() async {
    if (widget.nameController.text.isEmpty || widget.amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    final amount = double.tryParse(widget.amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    final payment = RecurringPayment(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: widget.nameController.text,
      amount: amount,
      frequency: _selectedFrequency,
      startDate: _startDate,
      iconName: widget.preset?.iconName,
      category: widget.preset?.category,
    );

    widget.onSave(payment);
  }

  String _getPreviewText() {
    final payment = RecurringPayment(
      id: '',
      name: widget.nameController.text.isEmpty ? 'Payment' : widget.nameController.text,
      amount: double.tryParse(widget.amountController.text) ?? 0.0,
      frequency: _selectedFrequency,
      startDate: _startDate,
    );
    return payment.previewText;
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);
    final currency = settingsAsync.valueOrNull?.currency ?? Currency.USD;

    return Dialog(
      backgroundColor: context.backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: 500,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.preset != null ? 'Add Payment' : 'Create Payment',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: context.onSurfaceColor,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                    color: context.onSurfaceMutedColor,
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: widget.nameController,
                      autofocus: widget.nameController.text.isEmpty,
                      decoration: InputDecoration(
                        labelText: 'Payment Name',
                        hintText: 'e.g., Gym Membership',
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
                          borderSide: BorderSide(
                            color: context.primaryColor,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: widget.amountController,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Amount',
                        prefixText: '${currency.name} ',
                        filled: true,
                        fillColor: context.surfaceColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<PaymentFrequency>(
                      value: _selectedFrequency,
                      decoration: InputDecoration(
                        labelText: 'Frequency',
                        filled: true,
                        fillColor: context.surfaceColor,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: PaymentFrequency.values.map((freq) {
                        String label;
                        switch (freq) {
                          case PaymentFrequency.weekly:
                            label = 'Weekly';
                            break;
                          case PaymentFrequency.biWeekly:
                            label = 'Bi-weekly';
                            break;
                          case PaymentFrequency.monthly:
                            label = 'Monthly';
                            break;
                          case PaymentFrequency.quarterly:
                            label = 'Quarterly';
                            break;
                          case PaymentFrequency.yearly:
                            label = 'Yearly';
                            break;
                        }
                        return DropdownMenuItem(
                          value: freq,
                          child: Text(label),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedFrequency = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _startDate,
                          firstDate: DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (date != null) {
                          setState(() {
                            _startDate = date;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: context.surfaceColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: context.borderColor),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Start Date',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: context.onSurfaceMutedColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat('MMM d, y').format(_startDate),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: context.onSurfaceColor,
                                  ),
                                ),
                              ],
                            ),
                            Icon(
                              Icons.calendar_today,
                              size: 20,
                              color: context.onSurfaceMutedColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
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
                              _getPreviewText(),
                              style: TextStyle(
                                fontSize: 12,
                                color: context.primaryColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _savePayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.primaryColor,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Add Payment',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CreateCustomCard extends StatelessWidget {
  final String searchText;
  final VoidCallback onTap;

  const _CreateCustomCard({
    required this.searchText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: context.primaryColor.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: context.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.add_circle_outline,
                color: context.primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    searchText,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: context.onSurfaceColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Create custom payment',
                    style: TextStyle(
                      fontSize: 12,
                      color: context.onSurfaceMutedColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: context.onSurfaceMutedColor,
            ),
          ],
        ),
      ),
    );
  }
}

class _PresetCard extends StatelessWidget {
  final RecurringPaymentPreset preset;
  final bool isSelected;
  final VoidCallback onTap;

  const _PresetCard({
    required this.preset,
    required this.isSelected,
    required this.onTap,
  });

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'netflix':
        return Icons.movie_outlined;
      case 'spotify':
        return Icons.music_note_outlined;
      case 'amazon':
        return Icons.shopping_bag_outlined;
      case 'youtube':
        return Icons.play_circle_outline;
      case 'phone':
        return Icons.phone_outlined;
      case 'home':
        return Icons.home_outlined;
      case 'fitness':
        return Icons.fitness_center_outlined;
      case 'wifi':
        return Icons.wifi_outlined;
      case 'bolt':
        return Icons.bolt_outlined;
      case 'shield':
        return Icons.shield_outlined;
      default:
        return Icons.payment_outlined;
    }
  }

  String _getFrequencyHint(PaymentFrequency freq) {
    switch (freq) {
      case PaymentFrequency.weekly:
        return 'Weekly';
      case PaymentFrequency.biWeekly:
        return 'Bi-weekly';
      case PaymentFrequency.monthly:
        return 'Monthly';
      case PaymentFrequency.quarterly:
        return 'Quarterly';
      case PaymentFrequency.yearly:
        return 'Yearly';
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? context.primaryColor.withOpacity(0.1)
              : context.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? context.primaryColor.withOpacity(0.5)
                : context.borderColor.withOpacity(0.5),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: (preset.color ?? context.primaryColor).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getIconData(preset.iconName),
                color: preset.color ?? context.primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    preset.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: context.onSurfaceColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getFrequencyHint(preset.defaultFrequency),
                    style: TextStyle(
                      fontSize: 12,
                      color: context.onSurfaceMutedColor,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: context.primaryColor,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
