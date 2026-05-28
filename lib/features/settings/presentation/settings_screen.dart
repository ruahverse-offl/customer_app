import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../notifications/providers/notification_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifGranted = ref.watch(notificationPermissionProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.notifications_outlined, color: AppColors.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Order notifications', style: AppTextStyles.label),
                      Text(
                        notifGranted == null
                            ? 'Checking…'
                            : notifGranted
                                ? 'Enabled — you\'ll get order updates'
                                : 'Disabled — tap to enable',
                        style: AppTextStyles.caption.copyWith(
                          color: notifGranted == true ? AppColors.secondary : AppColors.textMuted,
                        ),
                      ),
                    ])),
                    if (notifGranted == false)
                      Switch(
                        value: false,
                        onChanged: (_) =>
                            ref.read(notificationPermissionProvider.notifier).requestPermission(),
                        activeColor: AppColors.primary,
                      )
                    else if (notifGranted == true)
                      const Icon(Icons.check_circle_rounded, color: AppColors.secondary),
                  ]),
                  if (notifGranted == false) ...[
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: () =>
                          ref.read(notificationPermissionProvider.notifier).requestPermission(),
                      icon: const Icon(Icons.notifications_active_outlined, size: 18),
                      label: const Text('Enable Notifications'),
                      style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 44)),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

