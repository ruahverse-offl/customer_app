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
      appBar: AppBar(title: const Text('Notification Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Push Notifications', style: AppTextStyles.h3),
                const SizedBox(height: 4),
                Text('Receive updates for orders, deliveries, and promotions.',
                    style: AppTextStyles.bodySmall),
                const SizedBox(height: 16),
                Row(children: [
                  const Icon(Icons.notifications_outlined, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Order notifications', style: AppTextStyles.label),
                    Text(
                      notifGranted == null ? 'Checking…'
                          : notifGranted ? 'Enabled'
                          : 'Disabled — tap to enable',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: notifGranted == true ? AppColors.secondary : AppColors.textMuted,
                      ),
                    ),
                  ])),
                  if (notifGranted == false)
                    Switch(
                      value: false,
                      onChanged: (_) => ref.read(notificationPermissionProvider.notifier).requestPermission(),
                      activeColor: AppColors.primary,
                    )
                  else if (notifGranted == true)
                    const Icon(Icons.check_circle, color: AppColors.secondary),
                ]),
              ]),
            ),
          ),
          const SizedBox(height: 12),
          if (notifGranted == false)
            ElevatedButton.icon(
              onPressed: () => ref.read(notificationPermissionProvider.notifier).requestPermission(),
              icon: const Icon(Icons.notifications_active_outlined),
              label: const Text('Enable Notifications'),
            ),
        ],
      ),
    );
  }
}
