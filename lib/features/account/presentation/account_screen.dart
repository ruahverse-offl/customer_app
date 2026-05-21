import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).user;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Account')),
        body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.person_outline, size: 64, color: AppColors.textMuted),
          const SizedBox(height: 16),
          Text('Sign in to access your account', style: AppTextStyles.h3),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: ElevatedButton(
              onPressed: () => context.go('/login'),
              child: const Text('Sign In'),
            ),
          ),
        ])),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // User header
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Text(user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
                      style: AppTextStyles.h2.copyWith(color: AppColors.primary)),
                ),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(user.fullName, style: AppTextStyles.labelLarge),
                  Text(user.email, style: AppTextStyles.bodySmall),
                  if (user.mobileNumber != null)
                    Text(user.mobileNumber!, style: AppTextStyles.caption),
                ])),
              ]),
            ),
          ),
          const SizedBox(height: 16),
          _MenuItem(icon: Icons.person_outline, label: 'My Profile', onTap: () => context.push('/profile')),
          _MenuItem(icon: Icons.shopping_bag_outlined, label: 'My Orders', onTap: () => context.push('/profile/orders')),
          _MenuItem(icon: Icons.location_on_outlined, label: 'Saved Addresses', onTap: () => context.push('/profile/addresses')),
          _MenuItem(icon: Icons.calendar_today_outlined, label: 'Appointments', onTap: () => context.push('/profile/appointments')),
          _MenuItem(icon: Icons.notifications_outlined, label: 'Notification Settings', onTap: () => context.push('/profile/settings')),
          _MenuItem(icon: Icons.lock_outline, label: 'Change Password', onTap: () => context.push('/profile/change-password')),
          const SizedBox(height: 8),
          const Divider(),
          _MenuItem(icon: Icons.description_outlined, label: 'Terms & Conditions', onTap: () => context.push('/terms')),
          _MenuItem(icon: Icons.privacy_tip_outlined, label: 'Privacy Policy', onTap: () => context.push('/privacy')),
          _MenuItem(icon: Icons.assignment_return_outlined, label: 'Refund Policy', onTap: () => context.push('/refund-policy')),
          const SizedBox(height: 8),
          const Divider(),
          _MenuItem(
            icon: Icons.logout,
            label: 'Sign Out',
            color: AppColors.danger,
            onTap: () async {
              await ref.read(authNotifierProvider.notifier).logout();
            },
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  const _MenuItem({required this.icon, required this.label, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: color ?? AppColors.primary),
    title: Text(label, style: AppTextStyles.body.copyWith(color: color)),
    trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
    onTap: onTap,
    contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
  );
}
