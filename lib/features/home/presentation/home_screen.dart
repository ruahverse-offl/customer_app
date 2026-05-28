import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/brand_logo.dart';
import '../../../core/config/app_config.dart';
import '../../../core/config/app_constants.dart';
import '../../auth/providers/auth_provider.dart';
import '../../notifications/providers/notification_provider.dart';
import '../providers/delivery_settings_provider.dart';

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
    final deliverySettings = ref.watch(deliverySettingsProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── Floating app bar ───────────────────────────────────────────
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            flexibleSpace: const DecoratedBox(
              decoration: BoxDecoration(gradient: AppGradients.primary),
            ),
            titleSpacing: 16,
            title: Row(
              children: [
                Container(
                  width: 36, height: 36,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const BrandLogo(size: 30),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('New Balan Medical',
                        style: AppTextStyles.label.copyWith(color: Colors.white, fontSize: 15)),
                    Text('${AppConfig.shopCity}, ${AppConfig.shopState}',
                        style: AppTextStyles.caption.copyWith(color: Colors.white70, fontSize: 10)),
                  ],
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.person_outline_rounded),
                onPressed: () => context.go('/account'),
                tooltip: 'Account',
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Notification banner ──────────────────────────────────
                if (notifGranted == false)
                  _NotificationBanner(
                    onAllow: () => ref.read(notificationPermissionProvider.notifier).requestPermission(),
                  ),

                // ── Hero ─────────────────────────────────────────────────
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(gradient: AppGradients.primary),
                  child: Stack(
                    children: [
                      // Background decorative circles
                      Positioned(
                        right: -30, top: -30,
                        child: Container(
                          width: 160, height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.05),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 20, bottom: -20,
                        child: Container(
                          width: 90, height: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.07),
                          ),
                        ),
                      ),
                      // Content
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Personalized badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white.withOpacity(0.2)),
                              ),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                const Icon(Icons.star_rounded, color: Colors.amber, size: 13),
                                const SizedBox(width: 5),
                                Text("${AppConfig.shopCity}'s Trusted Pharmacy Since 1997",
                                    style: AppTextStyles.caption.copyWith(
                                        color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                              ]),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              user != null
                                  ? 'Hello, ${user.fullName.split(' ').first}.'
                                  : 'Your health,\nour priority.',
                              style: AppTextStyles.h1.copyWith(
                                  color: Colors.white, fontSize: 26, height: 1.2),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Medicines, clinic & insurance — all in one place.',
                              style: AppTextStyles.body.copyWith(color: Colors.white70, fontSize: 13),
                            ),
                            const SizedBox(height: 22),
                            Row(children: [
                              ElevatedButton.icon(
                                onPressed: () => context.go('/pharmacy'),
                                icon: const Icon(Icons.medication_rounded, size: 16),
                                label: const Text('Order Medicines'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: AppColors.primary,
                                  minimumSize: const Size(0, 42),
                                  padding: const EdgeInsets.symmetric(horizontal: 18),
                                  textStyle: AppTextStyles.label.copyWith(fontSize: 13),
                                ),
                              ),
                              const SizedBox(width: 10),
                              OutlinedButton(
                                onPressed: () => context.push('/clinic'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Colors.white54),
                                  minimumSize: const Size(0, 42),
                                  padding: const EdgeInsets.symmetric(horizontal: 18),
                                  textStyle: AppTextStyles.label.copyWith(fontSize: 13),
                                ),
                                child: const Text('Book Clinic'),
                              ),
                            ]),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Auto-scrolling promo carousel ─────────────────────────
                const SizedBox(height: 16),
                _BannerCarousel(
                  freeDeliveryThreshold: deliverySettings.valueOrNull?.freeDeliveryMinAmount,
                ),

                // ── Trust metrics ─────────────────────────────────────────
                const SizedBox(height: 16),
                const _StatsRow(),

                // ── Our Services ──────────────────────────────────────────
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(children: [
                    Expanded(child: Text('Our Services', style: AppTextStyles.h3)),
                  ]),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 126,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                      _ServiceCard(
                          icon: Icons.medication_rounded, label: 'Pharmacy',
                          subtitle: 'Order medicines', color: AppColors.primary,
                          onTap: () => context.go('/pharmacy')),
                      _ServiceCard(
                          icon: Icons.local_hospital_rounded, label: 'Clinic',
                          subtitle: 'See specialists', color: const Color(0xFF7C3AED),
                          onTap: () => context.push('/clinic')),
                      _ServiceCard(
                          icon: Icons.biotech_rounded, label: 'Polyclinic',
                          subtitle: 'Lab & tests', color: const Color(0xFF0891B2),
                          onTap: () => context.push('/polyclinic')),
                      _ServiceCard(
                          icon: Icons.verified_user_rounded, label: 'Insurance',
                          subtitle: 'Star Health plans', color: const Color(0xFF059669),
                          onTap: () => context.push('/insurance')),
                    ],
                  ),
                ),

                // ── Remaining sections ────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 28),

                      // Pharmacy highlights
                      Row(children: [
                        Expanded(child: Text('Your Trusted Pharmacy', style: AppTextStyles.h3)),
                        TextButton(
                          onPressed: () => context.go('/pharmacy'),
                          child: const Text('Browse all'),
                        ),
                      ]),
                      const SizedBox(height: 4),
                      Text('Genuine medicines · Doorstep delivery · Since 1997',
                          style: AppTextStyles.bodySmall),
                      const SizedBox(height: 14),
                      _PharmacyHighlights(onTap: () => context.go('/pharmacy')),
                      const SizedBox(height: 28),

                      // Insurance banner
                      _InsuranceBanner(onTap: () => context.push('/insurance')),
                      const SizedBox(height: 28),

                      // About Us
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

// ── Banner Carousel ────────────────────────────────────────────────────────────

class _BannerCarousel extends StatefulWidget {
  final double? freeDeliveryThreshold;
  const _BannerCarousel({this.freeDeliveryThreshold});

  @override
  State<_BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<_BannerCarousel> {
  final _ctrl = PageController();
  Timer? _timer;
  int _page = 0;
  bool _isDragging = false;

  List<({List<Color> colors, IconData icon, String title, String sub})> get _slides => [
    (
      colors: [Color(0xFF0056B3), Color(0xFF0077D4)],
      icon: Icons.local_shipping_rounded,
      title: 'Free Delivery',
      sub: widget.freeDeliveryThreshold != null
          ? 'On all orders above ₹${widget.freeDeliveryThreshold!.toStringAsFixed(0)} · ${AppConfig.shopCity} city'
          : 'On all orders above ₹500 · ${AppConfig.shopCity} city',
    ),
    (
      colors: [Color(0xFF059669), Color(0xFF047857)],
      icon: Icons.verified_rounded,
      title: '100% Genuine Medicines',
      sub: 'CDSCO certified · Original bill on every order',
    ),
    (
      colors: [Color(0xFFC2410C), Color(0xFFEA580C)],
      icon: Icons.timer_rounded,
      title: 'Same Day Delivery',
      sub: 'Order before 2 PM · Get it today',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || _isDragging) return;
      final next = (_page + 1) % _slides.length;
      _ctrl.animateToPage(next,
          duration: const Duration(milliseconds: 500), curve: Curves.easeInOut);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slides = _slides;
    return Column(
      children: [
        SizedBox(
          height: 88,
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollStartNotification &&
                  notification.dragDetails != null) {
                setState(() => _isDragging = true);
              } else if (notification is ScrollEndNotification) {
                setState(() => _isDragging = false);
              }
              return false;
            },
            child: PageView.builder(
            controller: _ctrl,
            onPageChanged: (i) => setState(() => _page = i),
            itemCount: slides.length,
            itemBuilder: (_, i) {
              final s = slides[i];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: s.colors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: s.colors.last.withOpacity(0.35),
                      blurRadius: 12, offset: const Offset(0, 4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(s.icon, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(s.title,
                          style: const TextStyle(
                            color: Colors.white, fontFamily: 'Outfit',
                            fontSize: 15, fontWeight: FontWeight.w700,
                          )),
                      const SizedBox(height: 3),
                      Text(s.sub,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontFamily: 'Inter', fontSize: 11,
                          )),
                    ],
                  )),
                ]),
              );
            },
          ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(slides.length, (i) => AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: _page == i ? 20.0 : 6.0,
            height: 6,
            decoration: BoxDecoration(
              color: _page == i ? AppColors.primary : AppColors.gray300,
              borderRadius: BorderRadius.circular(3),
            ),
          )),
        ),
      ],
    );
  }
}

// ── Trust metrics row ─────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: const [
          _Stat(value: '29+', label: 'Years\nExperience', icon: Icons.history_edu_rounded, color: AppColors.primary),
          SizedBox(width: 8),
          _Stat(value: '50K+', label: 'Happy\nCustomers', icon: Icons.people_rounded, color: Color(0xFF7C3AED)),
          SizedBox(width: 8),
          _Stat(value: '100%', label: 'Genuine\nProducts', icon: Icons.verified_rounded, color: Color(0xFF059669)),
          SizedBox(width: 8),
          _Stat(value: '1-Day', label: 'Fast\nDelivery', icon: Icons.delivery_dining_rounded, color: Color(0xFFD97706)),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  const _Stat({required this.value, required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 5),
            Text(value,
                style: TextStyle(
                  fontFamily: 'Outfit', fontWeight: FontWeight.w800,
                  fontSize: 14, color: color,
                )),
            const SizedBox(height: 2),
            Text(label,
                style: AppTextStyles.caption.copyWith(fontSize: 11, height: 1.25),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ── Service card ──────────────────────────────────────────────────────────────

class _ServiceCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  const _ServiceCard({
    required this.icon, required this.label, required this.subtitle,
    required this.color, required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      margin: const EdgeInsets.only(right: 10),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withOpacity(0.12), color.withOpacity(0.05)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.18)),
            ),
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [BoxShadow(
                      color: color.withOpacity(0.35),
                      blurRadius: 8, offset: const Offset(0, 3),
                    )],
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const Spacer(),
                Text(label,
                    style: AppTextStyles.label.copyWith(fontSize: 12.5)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: AppTextStyles.caption.copyWith(
                        color: AppColors.textMuted, fontSize: 10),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Pharmacy highlights ───────────────────────────────────────────────────────

class _PharmacyHighlights extends StatelessWidget {
  final VoidCallback onTap;
  const _PharmacyHighlights({required this.onTap});

  static const _items = [
    (Icons.local_shipping_outlined, 'Fast Delivery', 'At your door'),
    (Icons.description_outlined, 'Prescription Care', 'Easy upload'),
    (Icons.verified_outlined, 'Genuine Meds', '100% authentic'),
    (Icons.support_agent_outlined, '24/7 Support', 'Always here'),
    (Icons.psychology_outlined, 'Expert Guidance', 'Licensed staff'),
    (Icons.history_edu_outlined, 'Since 1997', '25+ years'),
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
              Text(item.$2,
                  style: AppTextStyles.caption.copyWith(
                      fontWeight: FontWeight.w700, fontSize: 11),
                  textAlign: TextAlign.center, maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              Text(item.$3,
                  style: AppTextStyles.caption.copyWith(
                      fontSize: 10, color: AppColors.textMuted),
                  textAlign: TextAlign.center, maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ])).toList(),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.medication_rounded, size: 16),
              label: const Text('Browse Medicines'),
              style: OutlinedButton.styleFrom(minimumSize: const Size(0, 42)),
            ),
          ),
        ]),
      ),
    ),
  );
}

// ── Insurance banner ──────────────────────────────────────────────────────────

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
        boxShadow: [BoxShadow(
          color: const Color(0xFFD97706).withOpacity(0.3),
          blurRadius: 12, offset: const Offset(0, 4),
        )],
      ),
      child: Row(children: [
        const Icon(Icons.health_and_safety_rounded, color: Colors.white, size: 36),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Star Health Insurance',
              style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700,
                fontSize: 15, fontFamily: 'Outfit',
              )),
          const SizedBox(height: 4),
          Text("Secure your family's future. Mani — Zonal Manager Club Achiever.",
              style: AppTextStyles.bodySmall.copyWith(color: Colors.white70)),
        ])),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Text('View Plans',
              style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12,
              )),
        ),
      ]),
    ),
  );
}

// ── About card ────────────────────────────────────────────────────────────────

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
            width: 60, height: 70,
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
              child: Text('Trusted Since 1997',
                  style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 6),
            Text('MANIKANDAN', style: AppTextStyles.labelLarge),
            Text('Founder & Director',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            Text('29+ years in pharma. 1000+ happy families served.',
                style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
          ])),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
        ]),
      ),
    ),
  );
}

// ── Location card ─────────────────────────────────────────────────────────────

class _LocationCard extends StatelessWidget {
  final VoidCallback onWhatsApp;
  final VoidCallback onCall;
  final VoidCallback onEmail;
  final VoidCallback onDirections;
  const _LocationCard({
    required this.onWhatsApp, required this.onCall,
    required this.onEmail, required this.onDirections,
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
                child: const Icon(Icons.store_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('New Balan Medical', style: AppTextStyles.label),
                const SizedBox(height: 2),
                Text(AppConstants.storeAddressLine,
                    style: AppTextStyles.bodySmall, overflow: TextOverflow.ellipsis),
                Text(AppConstants.storeCityStatePincode, style: AppTextStyles.bodySmall),
                const SizedBox(height: 4),
                Text(AppConstants.storePhone,
                    style: AppTextStyles.caption.copyWith(color: AppColors.primary)),
              ])),
            ]),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _ContactIcon(icon: Icons.chat_rounded, label: 'WhatsApp',
                  color: const Color(0xFF25D366), onTap: onWhatsApp),
              _ContactIcon(icon: Icons.phone_rounded, label: 'Call',
                  color: AppColors.primary, onTap: onCall),
              _ContactIcon(icon: Icons.mail_rounded, label: 'Email',
                  color: const Color(0xFF6366F1), onTap: onEmail),
              _ContactIcon(icon: Icons.directions_rounded, label: 'Directions',
                  color: const Color(0xFFEA4335), onTap: onDirections),
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
  const _ContactIcon({
    required this.icon, required this.label,
    required this.color, required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 52, height: 52,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 24),
      ),
      const SizedBox(height: 6),
      Text(label,
          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary, fontSize: 11)),
    ]),
  );
}

// ── Notification banner ───────────────────────────────────────────────────────

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
          Expanded(child: Text('Enable notifications for order updates',
              style: AppTextStyles.bodySmall)),
          TextButton(onPressed: onAllow, child: const Text('Allow')),
        ],
      ),
    );
  }
}
