import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/config/app_constants.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              title: const Text('About Us',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontFamily: 'Outfit', fontWeight: FontWeight.w700)),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.accent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                // Founder Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(children: [
                      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Stack(children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.asset(
                              'assets/images/mani-profile.jpg',
                              width: 90,
                              height: 110,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 90, height: 110,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(Icons.person, size: 48, color: AppColors.primary),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0, left: 0, right: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                              ),
                              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                const Icon(Icons.verified, color: Colors.white, size: 12),
                                const SizedBox(width: 3),
                                Text('Founder', style: AppTextStyles.caption.copyWith(color: Colors.white, fontSize: 10)),
                              ]),
                            ),
                          ),
                        ]),
                        const SizedBox(width: 16),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('The Visionary', style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis),
                          ),
                          const SizedBox(height: 8),
                          Text('MANIKANDAN', style: AppTextStyles.h3),
                          Text('Founder & Director', style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
                          const SizedBox(height: 8),
                          Text(
                            'With over 29 years of experience in the pharmaceutical industry, Mani founded NEW BALAN with a single mission: to make healthcare accessible and reliable for everyone.',
                            style: AppTextStyles.bodySmall,
                          ),
                        ])),
                      ]),
                      const SizedBox(height: 20),
                      // Achievements
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 2.4,
                        children: const [
                          _AchievementTile(icon: Icons.history, value: '29+', label: 'Years Experience', color: Color(0xFF3B82F6)),
                          _AchievementTile(icon: Icons.workspace_premium_outlined, value: '2022–2024', label: 'Zonal Manager Club', color: AppColors.secondary),
                          _AchievementTile(icon: Icons.star_outline, value: '1997', label: 'Established Since', color: Color(0xFFF59E0B)),
                          _AchievementTile(icon: Icons.favorite_outline, value: '1000+', label: 'Happy Families', color: Color(0xFFE11D48)),
                        ],
                      ),
                    ]),
                  ),
                ),
                const SizedBox(height: 24),

                // Journey
                Text('Our Journey', style: AppTextStyles.h3),
                const SizedBox(height: 4),
                Text('Key milestones from a local shop to a comprehensive healthcare hub.', style: AppTextStyles.bodySmall),
                const SizedBox(height: 14),
                const _Milestone(year: '1997', icon: Icons.store_outlined, title: 'Medical Shop Established',
                    desc: 'Inception of NEW BALAN Medical with a vision to serve the community with genuine pharmaceutical care.'),
                const _Milestone(year: '2022', icon: Icons.favorite_outline, title: 'Introduced Star Health',
                    desc: 'Expanded services into health insurance, partnering with Star Health to provide financial security to families.'),
                const _Milestone(year: '2023', icon: Icons.workspace_premium_outlined, title: 'Zonal Manager Club',
                    desc: 'Achieved the prestigious Zonal Manager Club status within the very first year of operations.'),
                const _Milestone(year: '2024', icon: Icons.trending_up, title: 'Branch Manager – Zonal Manager Club',
                    desc: 'Achieved a key milestone by becoming a Branch Manager and earning recognition in the Zonal Manager Club.',
                    isLast: true),
                const SizedBox(height: 24),

                // Mission & Vision
                Text('Mission & Vision', style: AppTextStyles.h3),
                const SizedBox(height: 14),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: _MissionCard(
                    icon: Icons.flag_outlined,
                    title: 'Our Mission',
                    body: 'To provide accessible, reliable, and quality healthcare services to our community, ensuring that every family receives the care and support they deserve.',
                    color: AppColors.primary,
                  )),
                  const SizedBox(width: 12),
                  Expanded(child: _MissionCard(
                    icon: Icons.visibility_outlined,
                    title: 'Our Vision',
                    body: 'To be the most trusted healthcare partner in our community, combining traditional care values with modern medical services and insurance solutions.',
                    color: AppColors.secondary,
                  )),
                ]),
                const SizedBox(height: 24),

                // Contact
                Text('Get in Touch', style: AppTextStyles.h3),
                const SizedBox(height: 4),
                Text('Reach us by phone, WhatsApp, or email.', style: AppTextStyles.bodySmall),
                const SizedBox(height: 14),
                _ContactButton(
                  icon: Icons.phone_outlined,
                  title: 'Phone',
                  subtitle: AppConstants.storePhone,
                  color: const Color(0xFF3B82F6),
                  onTap: () => _launch('tel:${AppConstants.storePhone}'),
                ),
                const SizedBox(height: 10),
                _ContactButton(
                  icon: Icons.chat_outlined,
                  title: 'WhatsApp',
                  subtitle: AppConstants.storePhone,
                  color: const Color(0xFF25D366),
                  onTap: () => _launch(AppConstants.storeWhatsApp),
                ),
                const SizedBox(height: 10),
                _ContactButton(
                  icon: Icons.mail_outline,
                  title: 'Email',
                  subtitle: AppConstants.storeEmail,
                  color: const Color(0xFF6366F1),
                  onTap: () => _launch('mailto:${AppConstants.storeEmail}'),
                ),
                const SizedBox(height: 32),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _AchievementTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  const _AchievementTile({required this.icon, required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Row(children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value, style: AppTextStyles.label.copyWith(color: color, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(label, style: AppTextStyles.caption.copyWith(fontSize: 9), maxLines: 1, overflow: TextOverflow.ellipsis),
          ])),
        ]),
      );
}

class _Milestone extends StatelessWidget {
  final String year;
  final IconData icon;
  final String title;
  final String desc;
  final bool isLast;
  const _Milestone({required this.year, required this.icon, required this.title, required this.desc, this.isLast = false});

  @override
  Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Column(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          if (!isLast)
            Container(width: 2, height: 48, color: AppColors.border),
        ]),
        const SizedBox(width: 14),
        Expanded(child: Padding(
          padding: EdgeInsets.only(bottom: isLast ? 0 : 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(year, style: AppTextStyles.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(height: 6),
            Text(title, style: AppTextStyles.label),
            const SizedBox(height: 4),
            Text(desc, style: AppTextStyles.bodySmall),
          ]),
        )),
      ]);
}

class _MissionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final Color color;
  const _MissionCard({required this.icon, required this.title, required this.body, required this.color});

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 10),
            Text(title, style: AppTextStyles.label),
            const SizedBox(height: 6),
            Text(body, style: AppTextStyles.bodySmall),
          ]),
        ),
      );
}

class _ContactButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;
  const _ContactButton({required this.icon, required this.title, required this.subtitle, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: AppTextStyles.label),
                Text(subtitle, style: AppTextStyles.bodySmall),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('Open', style: AppTextStyles.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ]),
          ),
        ),
      );
}
