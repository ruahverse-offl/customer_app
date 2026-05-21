import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/config/app_constants.dart';
import '../data/polyclinic_models.dart';
import '../data/polyclinic_repository.dart';

final _testsProvider = FutureProvider.autoDispose<List<PolyclinicTest>>((ref) {
  return ref.watch(polyclinicRepositoryProvider).getTests();
});

const _teal = Color(0xFF0891B2);

class PolyclinicScreen extends ConsumerWidget {
  const PolyclinicScreen({super.key});

  Future<void> _call() async {
    final uri = Uri.parse('tel:${AppConstants.storePhone}');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tests = ref.watch(_testsProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 150,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              title: const Text('Polyclinic Services',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontFamily: 'Outfit', fontWeight: FontWeight.w700)),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_teal, Color(0xFF0E7490)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.biotech_outlined, color: Colors.white70, size: 44),
                      SizedBox(height: 6),
                      Text('No booking required · Walk in', style: TextStyle(color: Colors.white60, fontSize: 12, fontFamily: 'Inter')),
                    ]),
                  ),
                ),
              ),
            ),
            backgroundColor: _teal,
            foregroundColor: Colors.white,
          ),

          SliverToBoxAdapter(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                width: double.infinity,
                color: _teal.withOpacity(0.06),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(children: [
                  const Icon(Icons.info_outline, color: _teal, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(
                    'No prior booking required. Contact us at the store for any test.',
                    style: AppTextStyles.bodySmall.copyWith(color: _teal),
                  )),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Available Tests & Services', style: AppTextStyles.h3),
                  const SizedBox(height: 4),
                  Text('Walk in or call for any test below.', style: AppTextStyles.bodySmall),
                ]),
              ),
            ]),
          ),

          tests.when(
            loading: () => const SliverToBoxAdapter(
              child: Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator())),
            ),
            error: (_, __) => const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: Text('Could not load tests. Please try again.')),
              ),
            ),
            data: (list) => list.isEmpty
                ? SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(48),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.biotech_outlined, size: 48, color: AppColors.textMuted),
                        const SizedBox(height: 12),
                        Text('No tests available at the moment.', style: AppTextStyles.body),
                      ]),
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => _TestCard(test: list[i], onCall: _call),
                        childCount: list.length,
                      ),
                    ),
                  ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_teal, Color(0xFF0E7490)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(children: [
                  const Icon(Icons.phone_in_talk_outlined, color: Colors.white, size: 36),
                  const SizedBox(width: 16),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Polyclinic Test Enquiries', style: AppTextStyles.labelLarge.copyWith(color: Colors.white)),
                    const SizedBox(height: 4),
                    Text('Call or visit the store directly. No booking needed.', style: AppTextStyles.bodySmall.copyWith(color: Colors.white70)),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _call,
                      child: Text(AppConstants.storePhone,
                          style: AppTextStyles.labelLarge.copyWith(color: Colors.white, decoration: TextDecoration.underline, decorationColor: Colors.white70)),
                    ),
                  ])),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

IconData _iconForName(String? name) {
  switch (name) {
    case 'TestTube': return Icons.science_outlined;
    case 'Activity': return Icons.monitor_heart_outlined;
    case 'Droplet': return Icons.water_drop_outlined;
    case 'Heart': return Icons.favorite_outline;
    case 'Stethoscope': return Icons.medical_services_outlined;
    case 'Microscope': return Icons.biotech_outlined;
    case 'FileText': return Icons.description_outlined;
    default: return Icons.science_outlined;
  }
}

class _TestCard extends StatelessWidget {
  final PolyclinicTest test;
  final VoidCallback onCall;
  const _TestCard({required this.test, required this.onCall});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _teal.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(_iconForName(test.iconName), color: _teal, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(test.name, style: AppTextStyles.label)),
              Text('₹${test.price.toStringAsFixed(0)}',
                  style: AppTextStyles.labelLarge.copyWith(color: _teal)),
            ]),
            if (test.description != null) ...[
              const SizedBox(height: 4),
              Text(test.description!, style: AppTextStyles.bodySmall),
            ],
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 6, children: [
              if (test.duration != null)
                _Chip(icon: Icons.schedule, label: test.duration!),
              if (test.fastingRequired)
                _Chip(icon: Icons.no_food_outlined, label: 'Fasting Required', color: AppColors.warning),
            ]),
            const SizedBox(height: 10),
            SizedBox(
              height: 36,
              child: OutlinedButton.icon(
                onPressed: onCall,
                icon: const Icon(Icons.phone_outlined, size: 15),
                label: const Text('Call to Book'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _teal,
                  side: const BorderSide(color: _teal),
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ),
          ])),
        ]),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  const _Chip({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: c.withOpacity(0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: c),
        const SizedBox(width: 4),
        Text(label, style: AppTextStyles.caption.copyWith(color: c, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}
