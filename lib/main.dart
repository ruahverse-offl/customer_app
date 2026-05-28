import 'dart:ui';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app.dart';
import 'core/widgets/error_widgets.dart';

@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Firebase isn't configured — drop the message silently. The main isolate
    // will already have logged the missing config; no need to repeat here.
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Framework widget-build errors → friendly card instead of red screen.
  ErrorWidget.builder = (FlutterErrorDetails details) {
    FlutterError.presentError(details); // still log to console
    return FriendlyErrorWidget(details: details);
  };

  // Framework non-widget errors (gesture handlers, render pipeline, etc.).
  FlutterError.onError = (FlutterErrorDetails details) {
    if (kDebugMode) {
      FlutterError.presentError(details);
    } else {
      debugPrint('FlutterError: ${details.exceptionAsString()}');
    }
  };

  // Platform-dispatcher errors (engine-level / native callbacks / uncaught
  // async errors that escape Flutter's main zone).
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    debugPrint('PlatformDispatcher error: $error');
    return true; // handled — don't crash
  };

  await dotenv.load(fileName: '.env');
  await Hive.initFlutter();

  // Firebase is optional: if google-services.json is missing the native plugin
  // skips registration and Firebase.initializeApp() throws. Catching it here
  // lets the rest of the app boot — push notifications just won't fire.
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
  } catch (e) {
    debugPrint('Firebase init skipped (no google-services.json): $e');
  }

  runApp(const ProviderScope(child: NewBalanApp()));
}
