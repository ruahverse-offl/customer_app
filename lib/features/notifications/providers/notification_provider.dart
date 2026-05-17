import 'package:flutter_riverpod/flutter_riverpod.dart';

// Push notifications are not yet configured.
// Add firebase_messaging + firebase_core to pubspec.yaml when ready,
// then replace this stub with the real FCM implementation.

class NotificationPermissionNotifier extends StateNotifier<bool?> {
  NotificationPermissionNotifier() : super(null);

  Future<void> requestPermission() async {
    // TODO: implement with firebase_messaging
    state = false;
  }

  Future<void> revokeToken() async {
    // TODO: implement with firebase_messaging
  }
}

final notificationPermissionProvider =
    StateNotifierProvider<NotificationPermissionNotifier, bool?>(
        (ref) => NotificationPermissionNotifier());
