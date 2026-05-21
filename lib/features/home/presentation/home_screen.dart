import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/config/app_config.dart';
import '../../../core/config/app_constants.dart';
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
                      // Services grid
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
                          _ServiceCard(icon: Icons.medication, label: 'Pharmacy', subtitle: 'Order medicines',
                              color: AppColors.primary, onTap: () => context.go('/pharmacy')),
                          _ServiceCard(icon: Icons.local_hospital_outlined, label: 'Clinic', subtitle: 'See specialists',
                              color: const Color(0xFF7C3AED), onTap: () => context.push('/clinic')),
                          _ServiceCard(icon: Icons.biotech_outlined, label: 'Polyclinic', subtitle: 'Lab & tests',
                              color: const Color(0xFF0891B2), onTap: () => context.push('/polyclinic')),
                          _ServiceCard(icon: Icons.verified_user_outlined, label: 'Insurance', subtitle: 'Star Health plans',
                              color: AppColors.secondary, onTap: () => context.push('/insurance')),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // Pharmacy highlights
                      Text('Your Trusted Pharmacy', style: AppTextStyles.h3),
                      const SizedBox(height: 4),
                      Text('Trusted Since 1997 · Genuine medicines · Doorstep delivery',
                          style: AppTextStyles.bodySmall),
                      const SizedBox(height: 14),
                      _PharmacyHighlights(onTap: () => context.go('/pharmacy')),
                      const SizedBox(height: 28),

                      // Insurance banner
                      _InsuranceBanner(onTap: () => context.push('/insurance')),
                      const SizedBox(height: 28),

                      // About Us / Founder
                      Text('About Us', style: AppTextStyles.h3),
                      const SizedBox(height: 12),
                      _AboutCard(onTap: () => context.push('/about')),
                      const SizedBox(height: 28),

                      // Find Us
                      Text('Find Us', style: AppTextStyles.h3),
                      const SizedBox(height: 12),
                      _LocationCard(
                        onWhatsApp: () => _launchUrl(AppConstants.storeWhatsApp),
                        onCall: () => _launchUrl('tel:${AppConstants.storePhone}'),
                        onEmail: () => _launchUrl('mailto:${AppConstants.storeEmail}'),
                        onDirections: () => _launchUrl(AppConstants.storeMapUrl),
                      ),
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
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  const _ServiceCard({required this.icon, required this.label, required this.subtitle, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.07),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.18)),
          ),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(height: 10),
              Text(label, style: AppTextStyles.label.copyWith(color: color)),
              Text(subtitle, style: AppTextStyles.caption.copyWith(color: color.withOpacity(0.7))),
            ],
          ),
        ),
      ),
    );
  }
}

class _PharmacyHighlights extends StatelessWidget {
  final VoidCallback onTap;
  const _PharmacyHighlights({required this.onTap});

  static const _items = [
    (Icons.local_shipping_outlined, 'Fast Delivery', 'Medicines at your door'),
    (Icons.description_outlined, 'Prescription Care', 'Easy upload & validation'),
    (Icons.verified_outlined, 'Genuine Medicines', '100% authentic products'),
    (Icons.support_agent_outlined, '24/7 Support', 'Always here for you'),
    (Icons.psychology_outlined, 'Expert Guidance', 'Licensed pharmacists'),
    (Icons.history_edu_outlined, 'Since 1997', '25+ years of service'),
  ];

  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 8,
            mainAxisSpacing: 12,
            childAspectRatio: 1.1,
            children: _items.map((item) => Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(item.$1, color: AppColors.primary, size: 20),
              ),
              const SizedBox(height: 6),
              Text(item.$2, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600, fontSize: 10),
                  textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(item.$3, style: AppTextStyles.caption.copyWith(fontSize: 9, color: AppColors.textMuted),
                  textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
            ])).toList(),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.medication, size: 16),
              label: const Text('Browse Medicines'),
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40)),
            ),
          ),
        ]),
      ),
    ),
  );
}

class _InsuranceBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _InsuranceBanner({required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFD97706), Color(0xFFB45309)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        const Icon(Icons.health_and_safety_outlined, color: Colors.white, size: 36),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Star Health Insurance', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15, fontFamily: 'Outfit')),
          const SizedBox(height: 4),
          Text('Secure your family\'s future with Mani — Zonal Manager Club Achiever.',
              style: AppTextStyles.bodySmall.copyWith(color: Colors.white70)),
        ])),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text('View Plans', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
        ),
      ]),
    ),
  );
}

class _AboutCard extends StatelessWidget {
  final VoidCallback onTap;
  const _AboutCard({required this.onTap});

  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Container(
            width: 60,
            height: 70,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/images/mani-profile.jpg',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.person, size: 32, color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('Trusted Since 1997', style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 6),
            Text('MANIKANDAN', style: AppTextStyles.labelLarge),
            Text('Founder & Director', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            Text('29+ years in pharma. 1000+ happy families served.',
                style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
          ])),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right, color: AppColors.textMuted),
        ]),
      ),
    ),
  );
}

class _LocationCard extends StatelessWidget {
  final VoidCallback onWhatsApp;
  final VoidCallback onCall;
  final VoidCallback onEmail;
  final VoidCallback onDirections;
  const _LocationCard({
    required this.onWhatsApp,
    required this.onCall,
    required this.onEmail,
    required this.onDirections,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.store_outlined, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('New Balan Medical', style: AppTextStyles.label),
                const SizedBox(height: 2),
                Text(AppConstants.storeAddressLine, style: AppTextStyles.bodySmall, overflow: TextOverflow.ellipsis),
                Text(AppConstants.storeCityStatePincode, style: AppTextStyles.bodySmall),
                const SizedBox(height: 4),
                Text(AppConstants.storePhone,
                    style: AppTextStyles.caption.copyWith(color: AppColors.primary)),
              ])),
            ]),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _ContactIcon(
                icon: Icons.chat_rounded,
                label: 'WhatsApp',
                color: const Color(0xFF25D366),
                onTap: onWhatsApp,
              ),
              _ContactIcon(
                icon: Icons.phone_rounded,
                label: 'Call',
                color: AppColors.primary,
                onTap: onCall,
              ),
              _ContactIcon(
                icon: Icons.mail_rounded,
                label: 'Email',
                color: const Color(0xFF6366F1),
                onTap: onEmail,
              ),
              _ContactIcon(
                icon: Icons.directions_rounded,
                label: 'Directions',
                color: const Color(0xFFEA4335),
                onTap: onDirections,
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

class _ContactIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ContactIcon({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      const SizedBox(height: 6),
      Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary, fontSize: 11)),
    ]),
  );
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
