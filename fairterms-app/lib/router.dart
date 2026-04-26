/// App routing configuration using GoRouter.
library;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'providers/auth_provider.dart';
import 'screens/analysis_loading_screen.dart';
import 'screens/bias_report_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/grievance_screen.dart';
import 'screens/heatmap_screen.dart';
import 'screens/history_screen.dart';
import 'screens/leaderboard_screen.dart';
import 'screens/login_screen.dart';
import 'screens/payment_terms_form_screen.dart';
import 'screens/profile_form_screen.dart';
import 'screens/admin_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';
import 'utils/constants.dart';

/// Creates the GoRouter instance with all app routes and auth redirect logic.
GoRouter createRouter(ProviderContainer container) {
  final authNotifier = RouterNotifier(container);

  return GoRouter(
    initialLocation: AppConstants.routeSplash,
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final authState =
          container.read(authStateProvider);
      final isGuest = container.read(guestModeProvider);

      // Don't redirect while auth state is loading (guest bypasses loading)
      if (!isGuest && authState.isLoading) return null;

      final isLoggedIn = isGuest || authState.value != null;
      final isSplash = state.matchedLocation == AppConstants.routeSplash;
      final isLogin = state.matchedLocation == AppConstants.routeLogin;

      // Let splash handle its own navigation
      if (isSplash) return null;

      // Redirect unauthenticated users to login
      if (!isLoggedIn && !isLogin) {
        return AppConstants.routeLogin;
      }

      // Redirect authenticated users away from login
      if (isLoggedIn && isLogin) {
        return AppConstants.routeDashboard;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppConstants.routeSplash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppConstants.routeLogin,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppConstants.routeDashboard,
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: AppConstants.routeProfile,
        builder: (context, state) => const ProfileFormScreen(),
      ),
      GoRoute(
        path: AppConstants.routePaymentTerms,
        builder: (context, state) => const PaymentTermsFormScreen(),
      ),
      GoRoute(
        path: '/analysis/:id/loading',
        builder: (context, state) {
          final analysisId = state.pathParameters['id']!;
          return AnalysisLoadingScreen(analysisId: analysisId);
        },
      ),
      GoRoute(
        path: '/analysis/:id/report',
        builder: (context, state) {
          final analysisId = state.pathParameters['id']!;
          return BiasReportScreen(analysisId: analysisId);
        },
      ),
      GoRoute(
        path: '/analysis/:id/grievance',
        builder: (context, state) {
          final analysisId = state.pathParameters['id']!;
          return GrievanceScreen(analysisId: analysisId);
        },
      ),
      GoRoute(
        path: AppConstants.routeHistory,
        builder: (context, state) => const HistoryScreen(),
      ),
      GoRoute(
        path: AppConstants.routeSettings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppConstants.routeHeatmap,
        builder: (context, state) => const HeatmapScreen(),
      ),
      GoRoute(
        path: AppConstants.routeLeaderboard,
        builder: (context, state) => const LeaderboardScreen(),
      ),
      GoRoute(
        path: AppConstants.routeAdmin,
        builder: (context, state) => const AdminScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 52, color: Colors.red),
            const SizedBox(height: 16),
            Text('Page not found: ${state.uri}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go(AppConstants.routeDashboard),
              child: const Text('Go to Dashboard'),
            ),
          ],
        ),
      ),
    ),
  );
}

/// A [ChangeNotifier] that listens to auth state changes to trigger
/// GoRouter redirects when authentication status changes.
class RouterNotifier extends ChangeNotifier {
  final ProviderContainer _container;
  late final ProviderSubscription<AsyncValue<User?>> _subscription;

  late final ProviderSubscription<bool> _guestSubscription;

  RouterNotifier(this._container) {
    _subscription = _container.listen(
      authStateProvider,
      (_, __) => notifyListeners(),
    );
    _guestSubscription = _container.listen(
      guestModeProvider,
      (_, __) => notifyListeners(),
    );
  }

  @override
  void dispose() {
    _subscription.close();
    _guestSubscription.close();
    super.dispose();
  }
}
