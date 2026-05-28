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
      return _GuestView();
    }

    final initials = user.fullName.trim().split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Gradient profile header
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF002D6B), Color(0xFF0056B3), Color(0xFF0077D4)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text('My Account',
                              style: const TextStyle(
                                fontFamily: 'Outfit',
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              )),
                          const Spacer(),
                          _HeaderIconButton(
                            icon: Icons.edit_outlined,
                            onTap: () => context.push('/profile'),
                            tooltip: 'Edit Profile',
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Container(
                            width: 68, height: 68,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.white.withOpacity(0.3), Colors.white.withOpacity(0.15)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                            ),
                            child: Center(
                              child: Text(initials,
                                  style: const TextStyle(
                                    fontFamily: 'Outfit',
                                    fontSize: 26,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  )),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(user.fullName,
                                    style: const TextStyle(
                                      fontFamily: 'Outfit',
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    )),
                                const SizedBox(height: 3),
                                Row(children: [
                                  Icon(Icons.email_outlined, size: 12, color: Colors.white.withOpacity(0.7)),
                                  const SizedBox(width: 4),
                                  Flexible(child: Text(user.email,
                                      style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Colors.white.withOpacity(0.8)),
                                      overflow: TextOverflow.ellipsis)),
                                ]),
                                if (user.mobileNumber != null) ...[
                                  const SizedBox(height: 2),
                                  Row(children: [
                                    Icon(Icons.phone_outlined, size: 12, color: Colors.white.withOpacity(0.7)),
                                    const SizedBox(width: 4),
                                    Text('+91 ${user.mobileNumber}',
                                        style: TextStyle(fontFamily: 'Inter', fontSize: 12, color: Colors.white.withOpacity(0.7))),
                                  ]),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Column(
                children: [
                  _SectionCard(
                    title: 'MY ACTIVITY',
                    children: [
                      _MenuItem(icon: Icons.shopping_bag_outlined, label: 'My Orders',
                          subtitle: 'Track & view order history',
                          color: AppColors.primary, onTap: () => context.push('/profile/orders')),
                      _MenuItem(icon: Icons.location_on_outlined, label: 'Saved Addresses',
                          subtitle: 'Manage delivery addresses',
                          color: const Color(0xFF7C3AED), onTap: () => context.push('/profile/addresses'),
                          showDivider: false),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _SectionCard(
                    title: 'SETTINGS',
                    children: [
                      _MenuItem(icon: Icons.person_outline_rounded, label: 'Edit Profile',
                          subtitle: 'Update your name & contact',
                          color: AppColors.secondary, onTap: () => context.push('/profile')),
                      _MenuItem(icon: Icons.palette_outlined, label: 'Appearance',
                          subtitle: 'Light, dark or system theme',
                          color: const Color(0xFF7C3AED), onTap: () => context.push('/profile/appearance')),
                      _MenuItem(icon: Icons.notifications_outlined, label: 'Notifications',
                          subtitle: 'Push & alert preferences',
                          color: const Color(0xFFD97706), onTap: () => context.push('/profile/settings')),
                      _MenuItem(icon: Icons.lock_outline_rounded, label: 'Change Password',
                          subtitle: 'Update your account password',
                          color: AppColors.gray600, onTap: () => context.push('/profile/change-password'),
                          showDivider: false),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _SectionCard(
                    title: 'LEGAL',
                    children: [
                      _MenuItem(icon: Icons.description_outlined, label: 'Terms & Conditions',
                          color: AppColors.textSecondary, onTap: () => context.push('/terms')),
                      _MenuItem(icon: Icons.privacy_tip_outlined, label: 'Privacy Policy',
                          color: AppColors.textSecondary, onTap: () => context.push('/privacy')),
                      _MenuItem(icon: Icons.assignment_return_outlined, label: 'Refund Policy',
                          color: AppColors.textSecondary, onTap: () => context.push('/refund-policy'),
                          showDivider: false),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _SectionCard(
                    children: [
                      _MenuItem(
                        icon: Icons.logout_rounded,
                        label: 'Sign Out',
                        subtitle: 'Log out of your account',
                        color: AppColors.danger,
                        onTap: () async => ref.read(authNotifierProvider.notifier).logout(),
                      ),
                      _MenuItem(
                        icon: Icons.delete_forever_outlined,
                        label: 'Delete Account',
                        subtitle: 'Permanently delete your account & data',
                        color: AppColors.danger,
                        onTap: () => context.push('/account/delete'),
                        showDivider: false,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuestView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF002D6B), Color(0xFF0056B3)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 44),
                child: Column(
                  children: [
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.35), width: 2),
                      ),
                      child: const Icon(Icons.person_rounded, size: 44, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    const Text('Welcome, Guest',
                        style: TextStyle(fontFamily: 'Outfit', fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
                    const SizedBox(height: 6),
                    Text('Sign in for orders, addresses & more',
                        style: TextStyle(fontFamily: 'Inter', fontSize: 13, color: Colors.white.withOpacity(0.8))),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: 220,
                      child: ElevatedButton(
                        onPressed: () => context.go('/login'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primary,
                          minimumSize: const Size(0, 48),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: const Text('Sign In / Register',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                _SectionCard(
                  title: 'LEGAL',
                  children: [
                    _MenuItem(icon: Icons.description_outlined, label: 'Terms & Conditions',
                        color: AppColors.textSecondary, onTap: () => context.push('/terms')),
                    _MenuItem(icon: Icons.privacy_tip_outlined, label: 'Privacy Policy',
                        color: AppColors.textSecondary, onTap: () => context.push('/privacy')),
                    _MenuItem(icon: Icons.assignment_return_outlined, label: 'Refund Policy',
                        color: AppColors.textSecondary, onTap: () => context.push('/refund-policy'),
                        showDivider: false),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;
  const _HeaderIconButton({required this.icon, required this.onTap, required this.tooltip});

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    ),
  );
}

class _SectionCard extends StatelessWidget {
  final String? title;
  final List<Widget> children;
  const _SectionCard({this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 8),
            child: Text(title!,
                style: AppTextStyles.caption.copyWith(
                    color: AppColors.textMuted, fontWeight: FontWeight.w700, letterSpacing: 0.8, fontSize: 10)),
          ),
        Card(child: Column(children: children)),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final Color color;
  final bool showDivider;
  const _MenuItem({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.onTap,
    required this.color,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: showDivider ? BorderRadius.zero : const BorderRadius.vertical(bottom: Radius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: AppTextStyles.body.copyWith(
                          color: color == AppColors.danger ? AppColors.danger : Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w600)),
                      if (subtitle != null)
                        Text(subtitle!, style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: AppColors.textMuted.withOpacity(0.5), size: 20),
              ],
            ),
          ),
        ),
        if (showDivider)
          const Divider(height: 1, indent: 70, endIndent: 0),
      ],
    );
  }
}
