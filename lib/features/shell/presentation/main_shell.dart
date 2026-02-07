import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';

class MainShell extends ConsumerWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = _calculateSelectedIndex(context);
    final theme = Theme.of(context);

    return Scaffold(
      extendBody: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      body: child,
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withOpacity(0.2),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: NavigationBar(
                  height: 72,
                  elevation: 0,
                  backgroundColor: Colors.transparent,
                  indicatorColor: Colors.transparent,
                  selectedIndex: selectedIndex,
                  labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
                  onDestinationSelected: (index) {
                    final paths = [
                      '/dashboard',
                      '/stats',
                      '/add-receipt',
                      '/saved-receipts',
                      '/settings',
                    ];
                    context.go(paths[index]);
                  },
                  destinations: [
                    _buildNavDestination(Icons.grid_view_outlined, Icons.grid_view_rounded, 'Home', 0, selectedIndex, theme),
                    _buildNavDestination(Icons.insights_outlined, Icons.insights_rounded, 'Stats', 1, selectedIndex, theme),
                    _buildAddDestination(theme, selectedIndex == 2),
                    _buildNavDestination(Icons.receipt_long_outlined, Icons.receipt_long_rounded, 'Saved', 3, selectedIndex, theme),
                    _buildNavDestination(Icons.person_outline_rounded, Icons.person_rounded, 'Settings', 4, selectedIndex, theme),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  NavigationDestination _buildNavDestination(IconData icon, IconData activeIcon, String label, int index, int selectedIndex, ThemeData theme) {
    final isSelected = index == selectedIndex;
    return NavigationDestination(
      icon: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          isSelected ? activeIcon : icon, 
          color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
          size: 26,
        ),
      ),
      label: label,
    );
  }

  NavigationDestination _buildAddDestination(ThemeData theme, bool isSelected) {
    return NavigationDestination(
      icon: AnimatedScale(
        scale: isSelected ? 1.1 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.secondary,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: theme.colorScheme.primary.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Icon(
            Icons.add_rounded, 
            color: theme.colorScheme.onPrimary, 
            size: 30,
          ),
        ),
      ),
      label: 'Add',
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/stats') || location.startsWith('/wrapped')) {
      return 1;
    }
    if (location.startsWith('/add-receipt')) {
      return 2;
    }
    if (location.startsWith('/saved-receipts')) {
      return 3;
    }
    if (location.startsWith('/settings') || location.startsWith('/financial-profile')) {
      return 4;
    }
    return 0;
  }
}
