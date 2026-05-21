import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/config/app_constants.dart';
import '../data/doctor_models.dart';
import '../data/doctor_repository.dart';

final _doctorDetailProvider = FutureProvider.autoDispose.family<Doctor, String>((ref, id) {
  return ref.watch(doctorRepositoryProvider).getDoctorById(id);
});

class SpecialistDetailScreen extends ConsumerWidget {
  final String doctorId;
  const SpecialistDetailScreen({super.key, required this.doctorId});

  Future<void> _call() async {
    final uri = Uri.parse('tel:${AppConstants.storePhone}');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docAsync = ref.watch(_doctorDetailProvider(doctorId));

    return Scaffold(
      appBar: AppBar(
        title: docAsync.whenOrNull(data: (d) => Text(d.name)) ?? const Text('Specialist'),
        leading: BackButton(onPressed: () => context.pop()),
        backgroundColor: const Color(0xFF7C3AED),
        foregroundColor: Colors.white,
      ),
      body: docAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text('Could not load specialist details.', style: AppTextStyles.body),
          const SizedBox(height: 16),
          TextButton(onPressed: () => context.pop(), child: const Text('Go Back')),
        ])),
        data: (doc) => _SpecialistDetail(doc: doc, onCall: _call),
      ),
    );
  }
}

class _SpecialistDetail extends StatelessWidget {
  final Doctor doc;
  final VoidCallback onCall;
  const _SpecialistDetail({required this.doc, required this.onCall});

  static const purple = Color(0xFF7C3AED);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Profile card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              Stack(alignment: Alignment.bottomRight, children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor: purple.withOpacity(0.1),
                  child: Text(doc.initials, style: AppTextStyles.h1.copyWith(color: purple, fontSize: 32)),
                ),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: doc.isActive ? AppColors.secondary : AppColors.textMuted,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                  ),
                ),
              ]),
              const SizedBox(height: 12),
              Text(doc.name, style: AppTextStyles.h2),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: purple.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(doc.specialty, style: AppTextStyles.label.copyWith(color: purple)),
              ),
              if (doc.subSpecialty != null) ...[
                const SizedBox(height: 6),
                Text(doc.subSpecialty!, style: AppTextStyles.bodySmall),
              ],
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: (doc.isActive ? AppColors.secondary : AppColors.textMuted).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  doc.isActive ? 'Available Now' : 'Currently Away',
                  style: AppTextStyles.label.copyWith(
                    color: doc.isActive ? AppColors.secondary : AppColors.textMuted,
                  ),
                ),
              ),
              if (doc.qualifications != null) ...[
                const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.verified_outlined, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(doc.qualifications!, style: AppTextStyles.bodySmall),
                ]),
              ],
              if (doc.consultationFee != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.gray100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(children: [
                    Text('Consultation Fee', style: AppTextStyles.caption),
                    Text('₹${doc.consultationFee!.toStringAsFixed(0)}',
                        style: AppTextStyles.h3.copyWith(color: purple)),
                  ]),
                ),
              ],
            ]),
          ),
        ),
        const SizedBox(height: 16),

        // Timings
        if (doc.displayMorning != null || doc.displayEvening != null) ...[
          Text('Consultation Timings', style: AppTextStyles.h3),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                if (doc.displayMorning != null)
                  Expanded(child: _TimingCard(session: 'Morning', time: doc.displayMorning!)),
                if (doc.displayMorning != null && doc.displayEvening != null) const SizedBox(width: 12),
                if (doc.displayEvening != null)
                  Expanded(child: _TimingCard(session: 'Evening', time: doc.displayEvening!)),
              ]),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // About
        if (doc.bio != null) ...[
          Text('About', style: AppTextStyles.h3),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(doc.bio!, style: AppTextStyles.body),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Experience
        if (doc.experience != null && doc.experience!.isNotEmpty) ...[
          Text('Experience', style: AppTextStyles.h3),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(doc.experience!, style: AppTextStyles.body),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Specializations
        if (doc.specializations != null && doc.specializations!.isNotEmpty) ...[
          Text('Specializations', style: AppTextStyles.h3),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: doc.specializations!.split(',').map((s) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: purple.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(s.trim(), style: AppTextStyles.caption.copyWith(color: purple, fontWeight: FontWeight.w600)),
                )).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // CTA
        ElevatedButton.icon(
          onPressed: onCall,
          icon: const Icon(Icons.phone_outlined),
          label: const Text('Call to Book Appointment'),
          style: ElevatedButton.styleFrom(backgroundColor: purple, foregroundColor: Colors.white),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _TimingCard extends StatelessWidget {
  final String session;
  final String time;
  const _TimingCard({required this.session, required this.time});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.gray100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.schedule, size: 16, color: AppColors.textSecondary),
            const SizedBox(width: 4),
            Text(session, style: AppTextStyles.labelSmall),
          ]),
          const SizedBox(height: 4),
          Text(time, style: AppTextStyles.body),
        ]),
      );
}
