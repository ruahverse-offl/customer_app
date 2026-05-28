import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/config/app_constants.dart';
import '../../../core/widgets/status_views.dart';
import '../data/doctor_models.dart';
import '../data/doctor_repository.dart';

final _doctorsProvider = FutureProvider.autoDispose<List<Doctor>>((ref) {
  return ref.watch(doctorRepositoryProvider).getDoctors();
});

class ClinicScreen extends ConsumerWidget {
  const ClinicScreen({super.key});

  Future<void> _call() async {
    final uri = Uri.parse('tel:${AppConstants.storePhone}');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final doctors = ref.watch(_doctorsProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              title: const Text('Clinic Services', style: TextStyle(color: Colors.white, fontSize: 18, fontFamily: 'Outfit', fontWeight: FontWeight.w700)),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Center(
                  child: Padding(
                    padding: EdgeInsets.only(top: 40),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.local_hospital_outlined, color: Colors.white70, size: 48),
                      SizedBox(height: 8),
                      Text('Expert Care', style: TextStyle(color: Colors.white60, fontSize: 12, fontFamily: 'Inter')),
                    ]),
                  ),
                ),
              ),
            ),
            backgroundColor: const Color(0xFF7C3AED),
            foregroundColor: Colors.white,
          ),

          SliverToBoxAdapter(
            child: Column(children: [
              // Feature strip
              Container(
                color: AppColors.card,
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _FeatureItem(icon: Icons.medical_services_outlined, label: 'Specialists'),
                    _FeatureItem(icon: Icons.phone_in_talk_outlined, label: 'Call to Book'),
                    _FeatureItem(icon: Icons.currency_rupee, label: 'Affordable'),
                    _FeatureItem(icon: Icons.today_outlined, label: 'Same-day'),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Polyclinic cross-link
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: InkWell(
                  onTap: () => context.push('/polyclinic'),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0891B2).withOpacity(0.06),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF0891B2).withOpacity(0.2)),
                    ),
                    child: Row(children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0891B2).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.biotech_outlined, color: Color(0xFF0891B2), size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Lab & Diagnostics', style: AppTextStyles.label.copyWith(color: const Color(0xFF0891B2))),
                        Text('Blood tests, imaging, and health checkups.', style: AppTextStyles.bodySmall),
                      ])),
                      const Icon(Icons.chevron_right, color: Color(0xFF0891B2)),
                    ]),
                  ),
                ),
              ),

              // Doctors list header
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Available Specialists', style: AppTextStyles.h3),
                  const SizedBox(height: 4),
                  Text('Choose your doctor and call us to schedule.', style: AppTextStyles.bodySmall),
                ]),
              ),
            ]),
          ),

          // Doctors
          doctors.when(
            loading: () => const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: LoadingView(label: 'Loading specialists…'),
              ),
            ),
            error: (_, __) => SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: ErrorStateView(
                  title: 'Could not load doctors',
                  onRetry: () => ref.invalidate(_doctorsProvider),
                ),
              ),
            ),
            data: (list) => list.isEmpty
                ? const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: EmptyStateView(
                        icon: Icons.medical_services_outlined,
                        title: 'No doctors available',
                        message: 'Our specialists will be back soon.',
                      ),
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (_, i) => _DoctorCard(doctor: list[i], onCall: _call),
                        childCount: list.length,
                      ),
                    ),
                  ),
          ),

          // Book CTA
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(children: [
                  const Icon(Icons.phone_in_talk_outlined, color: Colors.white, size: 36),
                  const SizedBox(width: 16),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Book Your Appointment', style: AppTextStyles.labelLarge.copyWith(color: Colors.white)),
                    const SizedBox(height: 4),
                    Text('Call us to schedule with any specialist.', style: AppTextStyles.bodySmall.copyWith(color: Colors.white70)),
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

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeatureItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF7C3AED).withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFF7C3AED), size: 20),
        ),
        const SizedBox(height: 6),
        Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
      ]);
}

class _DoctorCard extends StatelessWidget {
  final Doctor doctor;
  final VoidCallback onCall;
  const _DoctorCard({required this.doctor, required this.onCall});

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF7C3AED);
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => context.push('/clinic/specialist/${doctor.id}'),
        borderRadius: BorderRadius.circular(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Avatar
              Stack(children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: purple.withOpacity(0.1),
                  child: Text(doctor.initials, style: AppTextStyles.h3.copyWith(color: purple)),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: doctor.isActive ? AppColors.secondary : AppColors.textMuted,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ]),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text(doctor.name, style: AppTextStyles.labelLarge)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: (doctor.isActive ? AppColors.secondary : AppColors.textMuted).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      doctor.isActive ? 'Available' : 'Away',
                      style: AppTextStyles.caption.copyWith(
                        color: doctor.isActive ? AppColors.secondary : AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: purple.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(doctor.specialty, style: AppTextStyles.caption.copyWith(color: purple, fontWeight: FontWeight.w600)),
                ),
                if (doctor.subSpecialty != null) ...[
                  const SizedBox(height: 4),
                  Text(doctor.subSpecialty!, style: AppTextStyles.bodySmall),
                ],
                if (doctor.qualifications != null) ...[
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.verified_outlined, size: 13, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Expanded(child: Text(doctor.qualifications!, style: AppTextStyles.caption, maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ]),
                ],
              ])),
            ]),
          ),

          // Timings row
          if (doctor.displayMorning != null || doctor.displayEvening != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(children: [
                if (doctor.displayMorning != null)
                  Expanded(child: _TimingChip(label: 'Morning', time: doctor.displayMorning!)),
                if (doctor.displayMorning != null && doctor.displayEvening != null) const SizedBox(width: 8),
                if (doctor.displayEvening != null)
                  Expanded(child: _TimingChip(label: 'Evening', time: doctor.displayEvening!)),
              ]),
            ),

          // Fee + Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(children: [
              if (doctor.consultationFee != null) ...[
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Consultation', style: AppTextStyles.caption),
                  Text('₹${doctor.consultationFee!.toStringAsFixed(0)}',
                      style: AppTextStyles.labelLarge.copyWith(color: purple)),
                ]),
                const Spacer(),
              ] else
                const Spacer(),
              OutlinedButton.icon(
                onPressed: onCall,
                icon: const Icon(Icons.phone_outlined, size: 16),
                label: const Text('Call to Book'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: purple,
                  side: const BorderSide(color: Color(0xFF7C3AED)),
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _TimingChip extends StatelessWidget {
  final String label;
  final String time;
  const _TimingChip({required this.label, required this.time});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.gray100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.schedule, size: 12, color: AppColors.textMuted),
          const SizedBox(width: 4),
          Flexible(child: Text('$label: $time', style: AppTextStyles.caption, overflow: TextOverflow.ellipsis)),
        ]),
      );
}
