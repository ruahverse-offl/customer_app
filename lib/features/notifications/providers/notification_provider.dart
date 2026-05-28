import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/api/api_client.dart';
import '../../auth/providers/auth_provider.dart';

const _kPushEnabledKey = 'nb_push_enabled';
const _kLastTokenKey = 'nb_last_fcm_token';

const _kAndroidChannel = AndroidNotificationChannel(
  'orders_default',
  'Order Notifications',
  description: 'Order updates, refunds, and delivery alerts',
  importance: Importance.high,
);

final _localNotifications = FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

class NotificationPermissionNotifier extends StateNotifier<bool?> {
  final Ref _ref;
  String? _pushToken;

  /// Set by app.dart once the router is ready.
  void Function(String orderId)? onOrderNotificationTap;

  NotificationPermissionNotifier(this._ref) : super(null) {
    _init();
  }

  void _handleTap(RemoteMessage message) {
    final orderId = message.data['orderId'] as String?;
    if (orderId != null && orderId.isNotEmpty) {
      onOrderNotificationTap?.call(orderId);
    }
  }

  Future<void> _init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool(_kPushEnabledKey) ?? false;
      _pushToken = prefs.getString(_kLastTokenKey);

      await _setupLocalNotifications();
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      _listenForeground();
      FirebaseMessaging.onMessageOpenedApp.listen(_handleTap);
      FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
        _pushToken = token;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_kLastTokenKey, token);
        await _register(token);
      });

      final settings = await FirebaseMessaging.instance.getNotificationSettings();
      final granted = settings.authorizationStatus == AuthorizationStatus.authorized;
      state = granted;

      if (enabled && granted) await _getFcmToken();

      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial != null) _handleTap(initial);
    } catch (e) {
      // Firebase unavailable (no google-services.json) or runtime error.
      // Leave state as null so the home "Allow notifications" banner stays
      // hidden — there's nothing the user can do until Firebase is wired up.
      if (kDebugMode) print('[NotificationProvider] init error: $e');
      state = null;
    }
  }

  Future<void> _setupLocalNotifications() async {
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_kAndroidChannel);

    await _localNotifications.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );

    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true, badge: true, sound: true,
    );
  }

  void _listenForeground() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      final event = message.data['event'] as String? ?? '';
      final title = notification?.title ?? _eventTitle(event);
      final body = notification?.body ?? (message.data['body'] as String? ?? '');
      if (title.isEmpty && body.isEmpty) return;

      _localNotifications.show(
        message.hashCode,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _kAndroidChannel.id,
            _kAndroidChannel.name,
            channelDescription: _kAndroidChannel.description,
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
    });
  }

  String _eventTitle(String event) {
    switch (event) {
      case 'ORDER_CANCELLED_CUSTOMER': return 'Your order has been cancelled';
      case 'ORDER_SELF_CANCELLED': return 'Order cancelled';
      case 'ORDER_DELIVERY_RETURNED': return 'Delivery update';
      case 'ORDER_REFUND_COMPLETED': return 'Refund processed';
      default: return '';
    }
  }

  Future<void> requestPermission() async {
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true, badge: true, sound: true,
    );
    final granted = settings.authorizationStatus == AuthorizationStatus.authorized;
    state = granted;
    if (granted) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kPushEnabledKey, true);
      await _getFcmToken();
    }
  }

  Future<void> syncWithServer() async {
    if (state != true) return;
    if (_pushToken != null) {
      await _register(_pushToken!);
    } else {
      await _getFcmToken();
    }
  }

  Future<void> revokeOnLogout() async {
    final token = _pushToken;
    if (token == null) return;
    try {
      await _ref.read(dioProvider).post('/me/notification-settings/revoke', data: {
        'expo_push_token': token,
      });
    } catch (_) {}
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kPushEnabledKey);
    await prefs.remove(_kLastTokenKey);
    _pushToken = null;
    state = false;
  }

  Future<void> _getFcmToken() async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) return;
    if (token != _pushToken) {
      _pushToken = token;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kLastTokenKey, token);
    }
    await _register(token);
  }

  Future<void> _register(String token) async {
    final user = _ref.read(authNotifierProvider).user;
    if (user == null || user.roleCode == 'PUBLIC') return;
    try {
      await _ref.read(dioProvider).post('/me/notification-settings', data: {
        'expo_push_token': token,
        'device_platform': defaultTargetPlatform.name.toLowerCase(),
        'is_push_enabled': true,
      });
    } catch (_) {}
  }
}

final notificationPermissionProvider =
    StateNotifierProvider<NotificationPermissionNotifier, bool?>((ref) {
  return NotificationPermissionNotifier(ref);
});
