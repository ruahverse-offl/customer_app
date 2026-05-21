import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/pharmacy/presentation/pharmacy_screen.dart';
import '../../features/checkout/presentation/checkout_screen.dart';
import '../../features/account/presentation/account_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/profile/presentation/change_password_screen.dart';
import '../../features/orders/presentation/orders_screen.dart';
import '../../features/orders/presentation/order_detail_screen.dart';
import '../../features/addresses/presentation/addresses_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
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
  _AuthNotifier(this._ref) {
    _ref.listen(authNotifierProvider, (_, __) => notifyListeners());
  }

  static const _publicRoutes = {'/login', '/terms', '/privacy', '/refund-policy'};

  String? redirect(BuildContext context, GoRouterState state) {
    final isLoggedIn = _ref.read(authNotifierProvider).user != null;
    final isPublic = _publicRoutes.contains(state.matchedLocation);
    if (!isLoggedIn && !isPublic) return '/login';
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
          GoRoute(path: '/account', builder: (_, __) => const AccountScreen()),
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
