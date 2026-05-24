import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/providers/theme_provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/notifications/providers/notification_provider.dart';

class NewBalanApp extends ConsumerStatefulWidget {
  const NewBalanApp({super.key});
  @override
  ConsumerState<NewBalanApp> createState() => _NewBalanAppState();
}

class _NewBalanAppState extends ConsumerState<NewBalanApp> {
  bool _notifWired = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_notifWired) {
      _notifWired = true;
      final router = ref.read(routerProvider);
      // Navigate to order detail when a notification is tapped.
      ref.read(notificationPermissionProvider.notifier).onOrderNotificationTap =
          (orderId) => router.push('/profile/orders/$orderId');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Sync FCM token whenever user logs in.
    ref.listen(authNotifierProvider, (prev, next) {
      if (prev?.user == null && next.user != null) {
        ref.read(notificationPermissionProvider.notifier).syncWithServer();
      }
      if (prev?.user != null && next.user == null) {
        ref.read(notificationPermissionProvider.notifier).revokeOnLogout();
      }
    });

    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: 'New Balan Medical',
      theme: buildAppTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
