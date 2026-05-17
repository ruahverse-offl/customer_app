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
import '../../features/auth/providers/auth_provider.dart';
import '../shell/main_shell.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authNotifierProvider);

  return GoRouter(
    initialLocation: '/home',
    redirect: (context, state) {
      final isLoggedIn = authState.user != null;
      final isOnAuth = state.matchedLocation == '/login';

      if (!isLoggedIn && !isOnAuth) return '/login';
      if (isLoggedIn && isOnAuth) return '/home';
      return null;
    },
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
    ],
  );
});
