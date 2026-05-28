import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../notifications/providers/notification_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _confirmDisable(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Turn off notifications?'),
        content: const Text(
          "You'll stop receiving order updates, delivery alerts, and refund "
          "confirmations. You can turn them back on any time.",
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep on')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Turn off'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(notificationPermissionProvider.notifier).disable();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(notificationPermissionProvider.notifier);
    final notifGranted = ref.watch(notificationPermissionProvider);
    // `notifGranted == true` here means "the user has notifications ON".
    // Anything else (false or null) means OFF or not-yet-decided.
    final isOn = notifGranted == true;

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
                        color: (isOn ? AppColors.secondary : AppColors.primary).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isOn ? Icons.notifications_active_rounded : Icons.notifications_off_outlined,
                        color: isOn ? AppColors.secondary : AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Order notifications', style: AppTextStyles.label),
                          const SizedBox(height: 2),
                          Text(
                            notifGranted == null
                                ? 'Checking…'
                                : isOn
                                    ? "On — you'll receive order updates"
                                    : 'Off — you won\'t receive any push notifications',
                            style: AppTextStyles.caption.copyWith(
                              color: isOn ? AppColors.secondary : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: isOn,
                      onChanged: notifGranted == null
                          ? null
                          : (newValue) {
                              if (newValue) {
                                notifier.requestPermission();
                              } else {
                                _confirmDisable(context, ref);
                              }
                            },
                      activeColor: AppColors.secondary,
                    ),
                  ]),
                  if (!isOn && notifGranted != null) ...[
                    const SizedBox(height: 14),
                    OutlinedButton.icon(
                      onPressed: notifier.requestPermission,
                      icon: const Icon(Icons.notifications_active_outlined, size: 18),
                      label: const Text('Enable Notifications'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 44),
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Text(
                      isOn
                          ? "We send updates only for your orders — no marketing pings."
                          : "Tip: even if you turn this off, you can always see your order status under My Orders.",
                      style: AppTextStyles.caption.copyWith(color: AppColors.textMuted, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Pointer to OS-level controls. Useful when the user wants finer
          // control (sound, channel-level mutes) — we can't override those
          // from the app.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'For sound, vibration, or per-channel controls, open your '
              'phone\'s system Settings → Apps → New Balan Medical → Notifications.',
              style: AppTextStyles.caption.copyWith(color: AppColors.textMuted, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}
