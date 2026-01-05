import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:hisabi/core/constants/app_theme.dart';
import 'package:hisabi/core/utils/theme_extensions.dart';
import 'package:hisabi/features/receipts/providers/receipts_store.dart';

class SavedReceiptsScreen extends ConsumerWidget {
  const SavedReceiptsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final receiptsAsync = ref.watch(receiptsStoreProvider);
    final formatter = NumberFormat.currency(symbol: 'USD', decimalDigits: 2);

    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: isMobile ? 20.0 : 32.0,
        right: isMobile ? 20.0 : 32.0,
        top: isMobile ? 20.0 : 32.0,
        bottom: isMobile ? 100.0 : 32.0, // Extra padding for bottom nav
      ),
      child: receiptsAsync.when(
        data: (receipts) => receipts.isEmpty
            ? const _EmptyState()
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Saved receipts',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: receipts.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final r = receipts[receipts.length - 1 - index];
                      return Card(
                        child: ListTile(
                          title: Text(
                            r.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.onSurface,
                            ),
                          ),
                          subtitle: Text(
                            '${DateFormat.yMMMd().format(r.date)} • ${r.store}',
                            style: const TextStyle(
                                color: AppColors.onSurfaceMuted),
                          ),
                          trailing: Text(
                            formatter.format(r.total),
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.onSurface,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
        loading: () => const Center(
          child: Padding(
            padding: EdgeInsets.all(32.0),
            child: CircularProgressIndicator(),
          ),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 16),
              Text(
                'Error loading receipts',
                style: const TextStyle(color: AppColors.error),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.refresh(receiptsStoreProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            'lib/assets/logo.svg',
            width: 80,
            height: 80,
            colorFilter: ColorFilter.mode(
              context.onSurfaceMutedColor.withOpacity(0.4),
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No receipts saved yet.',
            style: TextStyle(color: context.onSurfaceMutedColor),
          ),
        ],
      ),
    );
  }
}
