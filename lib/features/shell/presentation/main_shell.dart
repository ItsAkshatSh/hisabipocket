import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hisabi/features/auth/providers/auth_provider.dart';
import 'package:hisabi/core/utils/theme_extensions.dart';

class MainShell extends ConsumerWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _BackgroundPatternPainter(),
            ),
          ),
          Column(
            children: [
              const _AppHeader(),
              Expanded(
                child: Container(
                  color: Colors.transparent,
                  child: child,
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: const _MobileBottomNav(),
    );
  }
}

class _BackgroundPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.withOpacity(0.03)
      ..strokeWidth = 1;

    // Draw subtle grid pattern
    const spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}


class _AppHeader extends ConsumerWidget {
  const _AppHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;

    return SafeArea(
      bottom: false,
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: context.backgroundColor,
          border: Border(
            bottom: BorderSide(
              color: context.borderColor.withOpacity(0.3),
              width: 0.5,
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        child: Row(
          children: [
            const Spacer(),
            // Profile icon button that opens settings
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => context.go('/settings'),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: context.borderColor.withOpacity(0.5),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: context.primaryColor.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                child: user?.pictureUrl != null && user!.pictureUrl!.isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          user.pictureUrl!,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              decoration: BoxDecoration(
                                color: context.primaryColor.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  user.name.substring(0, 1).toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: context.primaryColor,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          color: context.primaryColor.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            user?.name.substring(0, 1).toUpperCase() ?? 'U',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: context.primaryColor,
                            ),
                          ),
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


class _MobileBottomNav extends StatelessWidget {
  const _MobileBottomNav();

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(context);

    return Container(
      decoration: BoxDecoration(
        color: context.backgroundColor,
        border: Border(
          top: BorderSide(
            color: context.borderColor,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBottomNavItem(
                context,
                Icons.dashboard_outlined,
                'Home',
                '/dashboard',
                selectedIndex == 0,
              ),
              _buildBottomNavItem(
                context,
                Icons.bar_chart_outlined,
                'Stats',
                '/stats',
                selectedIndex == 1,
              ),
              _buildBottomNavItem(
                context,
                Icons.add_circle_outline,
                'Add',
                '/add-receipt',
                selectedIndex == 2,
                isCenter: true,
              ),
              _buildBottomNavItem(
                context,
                Icons.receipt_long_outlined,
                'Saved',
                '/saved-receipts',
                selectedIndex == 3,
              ),
              _buildBottomNavItem(
                context,
                Icons.settings_outlined,
                'Settings',
                '/settings',
                selectedIndex == 4,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem(
    BuildContext context,
    IconData icon,
    String label,
    String path,
    bool isActive, {
    bool isCenter = false,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            context.go(path);
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isCenter)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isActive
                          ? context.primaryColor
                          : context.primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: context.primaryColor.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      icon,
                      size: 24,
                      color: isActive ? Colors.white : context.primaryColor,
                    ),
                  )
                else
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      fontSize: isActive ? 22 : 20,
                      color: isActive
                          ? context.primaryColor
                          : context.onSurfaceMutedColor,
                    ),
                    child: Icon(
                      icon,
                      size: isActive ? 22 : 20,
                      color: isActive
                          ? context.primaryColor
                          : context.onSurfaceMutedColor,
                    ),
                  ),
                if (!isCenter) const SizedBox(height: 4),
                if (!isCenter)
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                      color: isActive
                          ? context.primaryColor
                          : context.onSurfaceMutedColor,
                    ),
                    child: Text(label),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/wrapped') || location.startsWith('/stats')) {
      return 1;
    }
    if (location.startsWith('/add-receipt')) {
      return 2;
    }
    if (location.startsWith('/saved-receipts')) {
      return 3;
    }
    if (location.startsWith('/settings')) {
      return 4;
    }
    return 0;
  }
}
