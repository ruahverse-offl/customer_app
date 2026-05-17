import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/api/api_client.dart';
import '../../../core/theme/app_theme.dart';

final _appointmentsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.watch(dioProvider);
  final res = await dio.get('/appointments/');
  final items = res.data['items'] ?? res.data as List;
  return (items as List).cast<Map<String, dynamic>>();
});

class AppointmentsScreen extends ConsumerWidget {
  const AppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appts = ref.watch(_appointmentsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Appointments')),
      body: appts.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Failed to load appointments', style: AppTextStyles.body)),
        data: (list) => list.isEmpty
            ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.calendar_today_outlined, size: 56, color: AppColors.textMuted),
                const SizedBox(height: 12),
                Text('No appointments', style: AppTextStyles.h3),
                const SizedBox(height: 6),
                Text('Visit our clinic to schedule an appointment', style: AppTextStyles.bodySmall),
              ]))
            : RefreshIndicator(
                onRefresh: () => ref.refresh(_appointmentsProvider.future),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  itemBuilder: (_, i) => _AppointmentCard(data: list[i]),
                ),
              ),
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _AppointmentCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final dateStr = data['appointment_date']?.toString() ?? '';
    DateTime? date = dateStr.isNotEmpty ? DateTime.tryParse(dateStr) : null;
    final status = data['status']?.toString() ?? '';
    final doctorName = data['doctor_name']?.toString() ?? 'Doctor';
    final note = data['note']?.toString() ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.person_outline, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(doctorName, style: AppTextStyles.label)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(status, style: AppTextStyles.caption.copyWith(color: AppColors.primary)),
            ),
          ]),
          if (date != null) ...[
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.calendar_today_outlined, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(DateFormat('dd MMM yyyy, hh:mm a').format(date.toLocal()), style: AppTextStyles.bodySmall),
            ]),
          ],
          if (note.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(note, style: AppTextStyles.bodySmall),
          ],
        ]),
      ),
    );
  }
}
