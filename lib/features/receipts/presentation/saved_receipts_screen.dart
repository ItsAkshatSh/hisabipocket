import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
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
        bottom: isMobile ? 100.0 : 32.0,
      ),
      child: receiptsAsync.when(
        data: (receipts) => receipts.isEmpty
            ? const _EmptyState()
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Saved receipts',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: context.onSurfaceColor,
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
                      return _AnimatedReceiptCard(
                        receipt: r,
                        formatter: formatter,
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
        error: (error, stack) => Builder(
          builder: (context) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: context.errorColor),
                const SizedBox(height: 16),
                Text(
                  'Error loading receipts',
                  style: TextStyle(color: context.errorColor),
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
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: context.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: context.primaryColor.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Icon(
                Icons.receipt_long_outlined,
                size: 56,
                color: context.primaryColor.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No receipts saved yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: context.onSurfaceColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start tracking your expenses by adding your first receipt',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: context.onSurfaceMutedColor,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnimatedReceiptCard extends StatefulWidget {
  final dynamic receipt;
  final NumberFormat formatter;

  const _AnimatedReceiptCard({
    required this.receipt,
    required this.formatter,
  });

  @override
  State<_AnimatedReceiptCard> createState() => _AnimatedReceiptCardState();
}

class _AnimatedReceiptCardState extends State<_AnimatedReceiptCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _elevationAnimation = Tween<double>(begin: 0.0, end: 8.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _controller.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _controller.reverse();
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedBuilder(
          animation: _elevationAnimation,
          builder: (context, child) {
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: context.surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: context.borderColor.withOpacity(0.5),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(
                      Theme.of(context).brightness == Brightness.dark
                          ? 0.3
                          : 0.08,
                    ),
                    blurRadius: _elevationAnimation.value,
                    offset: Offset(0, _elevationAnimation.value / 2),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    // Could add navigation to receipt details here
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.receipt.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  color: context.onSurfaceColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${DateFormat.yMMMd().format(widget.receipt.date)} • ${widget.receipt.store}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: context.onSurfaceMutedColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          widget.formatter.format(widget.receipt.total),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: context.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
