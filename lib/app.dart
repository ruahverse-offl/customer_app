import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/providers/theme_provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/brand_logo.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/notifications/providers/notification_provider.dart';

/// Root widget. Renders a splash MaterialApp while auth restores so we
/// don't mount the full router-based tree until the auth state is known.
///
/// Why this matters: when GoRouter is built with `refreshListenable` and
/// auth flips from restoring → ready, the redirect re-evaluates and
/// rebuilds the tree mid-frame. On cold start this races against
/// inherited-widget teardown and trips the
/// `_dependents.isEmpty is not true` assertion. Deferring router creation
/// removes the race entirely — there is no mid-flight tree to tear down,
/// just a clean top-level MaterialApp swap.
class NewBalanApp extends ConsumerStatefulWidget {
  const NewBalanApp({super.key});
  @override
  ConsumerState<NewBalanApp> createState() => _NewBalanAppState();
}

class _NewBalanAppState extends ConsumerState<NewBalanApp> {
  bool _notifWired = false;

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authNotifierProvider);
    final themeMode = ref.watch(themeModeProvider);

    // Phase 1 — auth still restoring. Render a minimal app showing the
    // brand splash. Crucially, no GoRouter, no nested Scaffolds, no
    // InheritedWidgets that the user-facing tree depends on.
    if (authState.isRestoring) {
      return MaterialApp(
        title: 'New Balan Medical',
        theme: buildAppTheme(),
        darkTheme: buildDarkTheme(),
        themeMode: themeMode,
        debugShowCheckedModeBanner: false,
        home: const _SplashScreen(),
      );
    }

    // Phase 2 — auth ready. Build the real app exactly once.
    // ref.listen survives across the phase transition because this
    // ConsumerState is the same instance both times.
    ref.listen(authNotifierProvider, (prev, next) {
      if (prev?.user == null && next.user != null) {
        ref.read(notificationPermissionProvider.notifier).syncWithServer();
      }
      if (prev?.user != null && next.user == null) {
        ref.read(notificationPermissionProvider.notifier).revokeOnLogout();
      }
    });

    final router = ref.watch(routerProvider);

    // Wire the notification-tap → router.push hookup once. We can't do this
    // in didChangeDependencies because that fires during Phase 1 when the
    // router doesn't exist yet.
    if (!_notifWired) {
      _notifWired = true;
      ref.read(notificationPermissionProvider.notifier).onOrderNotificationTap =
          (orderId) => router.push('/profile/orders/$orderId');
    }

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

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.primary),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const BrandLogo(size: 76),
            ),
            const SizedBox(height: 24),
            Text(
              'New Balan Medical',
              style: AppTextStyles.h2.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 6),
            Text(
              'Loading your account…',
              style: AppTextStyles.body.copyWith(color: Colors.white.withOpacity(0.85)),
            ),
            const SizedBox(height: 32),
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
