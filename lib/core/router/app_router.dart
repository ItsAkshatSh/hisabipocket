import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hisabi/features/auth/presentation/login_screen.dart';
import 'package:hisabi/features/auth/providers/auth_provider.dart';
import 'package:hisabi/features/dashboard/presentation/dashboard_screen.dart';
import 'package:hisabi/features/receipts/presentation/add_receipt_screen.dart';
import 'package:hisabi/features/receipts/presentation/voice_quick_add_screen.dart';
import 'package:hisabi/features/receipts/presentation/saved_receipts_screen.dart';
import 'package:hisabi/features/shell/presentation/main_shell.dart';
import 'package:hisabi/features/settings/presentation/settings_screen.dart';
import 'package:hisabi/features/settings/presentation/privacy_policy_screen.dart';
import 'package:hisabi/features/settings/presentation/terms_of_service_screen.dart';
import 'package:hisabi/features/wrapped/presentation/week_wrapped_screen.dart';
import 'package:hisabi/features/insights/presentation/insights_screen.dart';
import 'package:hisabi/features/financial_profile/presentation/financial_profile_screen.dart';

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
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
  // Watch authProvider to rebuild router when auth state changes
  ref.watch(authProvider);
  
  return GoRouter(
    initialLocation: '/dashboard',
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
            path: '/wrapped',
            builder: (context, state) {
              final weekStart = state.uri.queryParameters['weekStart'];
              final date = weekStart != null ? DateTime.tryParse(weekStart) : null;
              return WeekWrappedScreen(weekStart: date);
            },
          ),
          GoRoute(
            path: '/stats',
            builder: (context, state) => const InsightsScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/financial-profile',
            builder: (context, state) => const FinancialProfileScreen(),
          ),
          GoRoute(
            path: '/privacy-policy',
            builder: (context, state) => const PrivacyPolicyScreen(),
          ),
          GoRoute(
            path: '/terms-of-service',
            builder: (context, state) => const TermsOfServiceScreen(),
          ),
        ],
      ),
    ],
    redirect: (BuildContext context, GoRouterState state) {
      final authState = ref.read(authProvider);
      final authStatus = authState.status;
      final isAuthenticated = authStatus == AuthStatus.authenticated;
      final isUnauthenticated = authStatus == AuthStatus.unauthenticated;
      final isLoginPage = state.uri.path == '/login';
      
      // Wait for auth check to complete (unknown status means still checking)
      if (authStatus == AuthStatus.unknown) {
        return null;
      }
      
      // Handle home widget redirects
      if (state.uri.scheme == 'homewidget') {
        if (state.uri.host == 'quick_voice_add') {
          return '/voice-add';
        }
        if (state.uri.host == 'open_dashboard') {
          return '/dashboard';
        }
      }
      
      // If not authenticated and not on login page, redirect to login
      if (isUnauthenticated && !isLoginPage) {
        return '/login';
      }
      
      // If authenticated and on login page, redirect to dashboard
      if (isAuthenticated && isLoginPage) {
        return '/dashboard';
      }
      
      return null;
    },
  );
});
