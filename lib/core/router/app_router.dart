import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/pharmacy/presentation/pharmacy_screen.dart';
import '../../features/checkout/presentation/checkout_screen.dart';
import '../../features/account/presentation/account_screen.dart';
import '../../features/account/presentation/delete_account_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/profile/presentation/change_password_screen.dart';
import '../../features/orders/presentation/orders_screen.dart';
import '../../features/orders/presentation/order_detail_screen.dart';
import '../../features/addresses/presentation/addresses_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/appearance/presentation/appearance_screen.dart';
import '../../features/appointments/presentation/appointments_screen.dart';
import '../../features/clinic/presentation/clinic_screen.dart';
import '../../features/clinic/presentation/specialist_detail_screen.dart';
import '../../features/polyclinic/presentation/polyclinic_screen.dart';
import '../../features/about/presentation/about_screen.dart';
import '../../features/insurance/presentation/insurance_screen.dart';
import '../../features/legal/presentation/legal_screens.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../shell/main_shell.dart';

class _AuthNotifier extends ChangeNotifier {
  final Ref _ref;
  bool _wasLoggedIn;
  bool _wasRestoring;

  _AuthNotifier(this._ref)
      : _wasLoggedIn = _ref.read(authNotifierProvider).user != null,
        _wasRestoring = _ref.read(authNotifierProvider).isRestoring {
    _ref.listen(authNotifierProvider, (prev, next) {
      final nowLoggedIn = next.user != null;
      final nowRestoring = next.isRestoring;
      // Only refresh routing when something the redirect() cares about
      // changes — login status or "still restoring". Skipping no-op
      // notifications avoids GoRouter re-evaluations on every profile
      // refresh, which was causing cold-start _dependents.isEmpty
      // assertions when the rebuild fired mid-frame.
      if (nowLoggedIn == _wasLoggedIn && nowRestoring == _wasRestoring) return;
      _wasLoggedIn = nowLoggedIn;
      _wasRestoring = nowRestoring;
      // Defer to the next frame so notifyListeners() never fires during a
      // build, which is the other half of the same crash class.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (hasListeners) notifyListeners();
      });
    });
  }

  // Browsing is allowed without login; only cart/checkout and account require login
  static const _publicRoutes = {
    '/login',
    '/terms', '/privacy', '/refund-policy',
    '/home', '/pharmacy',
    '/clinic', '/polyclinic',
    '/about', '/insurance',
  };

  String? redirect(BuildContext context, GoRouterState state) {
    final authState = _ref.read(authNotifierProvider);
    if (authState.isRestoring) return null; // wait — don't redirect before restore completes
    final isLoggedIn = authState.user != null;
    final isPublic = _publicRoutes.contains(state.matchedLocation);
    if (!isLoggedIn && !isPublic) return '/home'; // guest → keep on home, gate at action level
    if (isLoggedIn && state.matchedLocation == '/login') return '/home';
    return null;
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _AuthNotifier(ref);

  return GoRouter(
    initialLocation: '/home',
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      ShellRoute(
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
          GoRoute(path: '/pharmacy', builder: (_, __) => const PharmacyScreen()),
          GoRoute(path: '/checkout', builder: (_, __) => const CheckoutScreen()),
          GoRoute(
            path: '/account',
            builder: (_, __) => const AccountScreen(),
            routes: [
              GoRoute(path: 'delete', builder: (_, __) => const DeleteAccountScreen()),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/profile',
        builder: (_, __) => const ProfileScreen(),
        routes: [
          GoRoute(path: 'change-password', builder: (_, __) => const ChangePasswordScreen()),
          GoRoute(path: 'orders', builder: (_, __) => const OrdersScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (_, state) => OrderDetailScreen(orderId: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(path: 'addresses', builder: (_, __) => const AddressesScreen()),
          GoRoute(path: 'settings', builder: (_, __) => const SettingsScreen()),
          GoRoute(path: 'appearance', builder: (_, __) => const AppearanceScreen()),
          GoRoute(path: 'appointments', builder: (_, __) => const AppointmentsScreen()),
        ],
      ),
      GoRoute(
        path: '/clinic',
        builder: (_, __) => const ClinicScreen(),
        routes: [
          GoRoute(
            path: 'specialist/:id',
            builder: (_, state) => SpecialistDetailScreen(doctorId: state.pathParameters['id']!),
          ),
        ],
      ),
      GoRoute(path: '/polyclinic', builder: (_, __) => const PolyclinicScreen()),
      GoRoute(path: '/about', builder: (_, __) => const AboutScreen()),
      GoRoute(path: '/insurance', builder: (_, __) => const InsuranceScreen()),
      GoRoute(path: '/terms', builder: (_, __) => const TermsScreen()),
      GoRoute(path: '/privacy', builder: (_, __) => const PrivacyScreen()),
      GoRoute(path: '/refund-policy', builder: (_, __) => const RefundScreen()),
    ],
  );
});
