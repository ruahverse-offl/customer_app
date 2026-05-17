import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/config/app_config.dart';
import '../../auth/providers/auth_provider.dart';
import '../../notifications/providers/notification_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authNotifierProvider).user;
    final notifGranted = ref.watch(notificationPermissionProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('New Balan Medical', style: AppTextStyles.labelLarge.copyWith(color: Colors.white)),
                Text('${AppConfig.shopCity}, ${AppConfig.shopState}',
                    style: AppTextStyles.caption.copyWith(color: Colors.white70)),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.person_outline),
                onPressed: () => context.go('/account'),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                // Permission banner
                if (notifGranted == false)
                  _NotificationBanner(onAllow: () => ref.read(notificationPermissionProvider.notifier).requestPermission()),

                // Hero section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary, AppColors.accent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user != null ? 'Hello, ${user.fullName.split(' ').first}!' : 'Your health, our priority',
                        style: AppTextStyles.h2.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      Text('Order medicines, book appointments, get delivered to your door.',
                          style: AppTextStyles.body.copyWith(color: Colors.white70)),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () => context.go('/pharmacy'),
                        icon: const Icon(Icons.medication, size: 18),
                        label: const Text('Order Medicines'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primary,
                          minimumSize: const Size(0, 44),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Our Services', style: AppTextStyles.h3),
                      const SizedBox(height: 16),
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.3,
                        children: [
                          _ServiceCard(icon: Icons.medication, label: 'Pharmacy', color: AppColors.primary,
                              onTap: () => context.go('/pharmacy')),
                          _ServiceCard(icon: Icons.local_hospital_outlined, label: 'Clinic', color: const Color(0xFF7C3AED),
                              onTap: () {}),
                          _ServiceCard(icon: Icons.health_and_safety_outlined, label: 'Polyclinic', color: const Color(0xFF0891B2),
                              onTap: () {}),
                          _ServiceCard(icon: Icons.verified_user_outlined, label: 'Insurance', color: AppColors.secondary,
                              onTap: () {}),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text('Find Us', style: AppTextStyles.h3),
                      const SizedBox(height: 12),
                      _LocationCard(onWhatsApp: () => _launchUrl('https://wa.me/919895000000'),
                          onCall: () => _launchUrl('tel:+919895000000'),
                          onDirections: () => _launchUrl('https://maps.google.com/?q=New+Balan+Medical+Palakkad')),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ServiceCard({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(label, style: AppTextStyles.label.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  final VoidCallback onWhatsApp;
  final VoidCallback onCall;
  final VoidCallback onDirections;
  const _LocationCard({required this.onWhatsApp, required this.onCall, required this.onDirections});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.location_on_outlined, color: AppColors.primary, size: 18),
              const SizedBox(width: 6),
              Text('New Balan Medical, Palakkad - 678001', style: AppTextStyles.body),
            ]),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: OutlinedButton.icon(
                  onPressed: onWhatsApp,
                  icon: const Icon(Icons.chat_outlined, size: 16),
                  label: const Text('WhatsApp'),
                  style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40)),
                )),
                const SizedBox(width: 8),
                Expanded(child: OutlinedButton.icon(
                  onPressed: onCall,
                  icon: const Icon(Icons.phone_outlined, size: 16),
                  label: const Text('Call'),
                  style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40)),
                )),
                const SizedBox(width: 8),
                Expanded(child: ElevatedButton.icon(
                  onPressed: onDirections,
                  icon: const Icon(Icons.directions, size: 16),
                  label: const Text('Directions'),
                  style: ElevatedButton.styleFrom(minimumSize: const Size(0, 40)),
                )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationBanner extends StatelessWidget {
  final VoidCallback onAllow;
  const _NotificationBanner({required this.onAllow});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.primary.withOpacity(0.1),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.notifications_outlined, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text('Enable notifications for order updates', style: AppTextStyles.bodySmall)),
          TextButton(onPressed: onAllow, child: const Text('Allow')),
        ],
      ),
    );
  }
}
