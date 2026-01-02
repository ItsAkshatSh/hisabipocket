import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisabi/features/auth/presentation/login_screen.dart';
import 'package:hisabi/features/dashboard/presentation/dashboard_screen.dart';
import 'package:hisabi/features/receipts/presentation/add_receipt_screen.dart';
import 'package:hisabi/features/receipts/presentation/voice_quick_add_screen.dart';
import 'package:hisabi/features/receipts/presentation/saved_receipts_screen.dart';
import 'package:hisabi/features/auth/providers/auth_provider.dart';
import 'package:hisabi/features/shell/presentation/main_shell.dart';
import 'package:hisabi/features/settings/presentation/settings_screen.dart';

// Helper to bridge Riverpod StateNotifier to GoRouter's refreshListenable
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners();
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }
  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: authState.status == AuthStatus.authenticated ? '/dashboard' : '/login',
    refreshListenable: GoRouterRefreshStream(ref.watch(authProvider.notifier).stream),
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/add-receipt',
            builder: (context, state) => const AddReceiptScreen(),
          ),
          GoRoute(
            path: '/voice-add',
            builder: (context, state) => const VoiceQuickAddScreen(),
          ),
          GoRoute(
            path: '/saved-receipts',
            builder: (context, state) => const SavedReceiptsScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
    redirect: (context, state) {
      // Handle home widget deep links
      if (state.uri.scheme == 'homewidget') {
        if (state.uri.host == 'quick_voice_add') {
          return '/voice-add';
        }
        if (state.uri.host == 'open_dashboard') {
          return '/dashboard';
        }
      }

      final loggedIn = authState.status == AuthStatus.authenticated;
      final loggingIn = state.matchedLocation == '/login';

      if (!loggedIn && !loggingIn) {
        return '/login';
      }
      
      if (loggedIn && loggingIn) {
        return '/dashboard';
      }
      
      return null;
    },
  );
});