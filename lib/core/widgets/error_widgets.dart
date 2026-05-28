import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Shown by Flutter's `ErrorWidget.builder` instead of the red-yellow stripe
/// screen. Looks intentional — the user sees a calm card with a retry hint,
/// not a screaming framework dump.
class FriendlyErrorWidget extends StatelessWidget {
  final FlutterErrorDetails details;
  const FriendlyErrorWidget({super.key, required this.details});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.danger.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.error_outline_rounded,
                  size: 36, color: AppColors.danger),
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              textAlign: TextAlign.center,
              style: AppTextStyles.h3,
            ),
            const SizedBox(height: 8),
            Text(
              "We've hit a small hiccup. Try again in a moment — if it keeps "
              "happening, sign out and back in.",
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(color: AppColors.textSecondary),
            ),
            if (kDebugMode) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.gray100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  details.exception.toString(),
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontFamily: 'monospace',
                  ),
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Friendly snackbar for caught exceptions. Auto-classifies common failures
/// (network, auth, server 5xx, validation) into short user-readable text.
///
/// Usage:
///   try { ... } catch (e) { showAppError(context, e); }
void showAppError(BuildContext context, Object error, {String? fallback}) {
  if (!context.mounted) return;
  final messenger = ScaffoldMessenger.of(context);
  final message = appErrorMessage(error, fallback: fallback);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
      backgroundColor: AppColors.danger,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    ),
  );
}

/// Friendly success/info snackbar — companion to [showAppError].
void showAppSuccess(BuildContext context, String message) {
  if (!context.mounted) return;
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Row(
        children: [
          const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
      backgroundColor: AppColors.secondary,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    ),
  );
}

/// Classify a thrown object into a short, user-readable message.
/// Centralised so every screen produces the same wording for the same failure.
String appErrorMessage(Object error, {String? fallback}) {
  if (error is DioException) {
    final response = error.response;
    if (response == null) {
      // No HTTP response = network is unreachable.
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'The request timed out. Please try again.';
        case DioExceptionType.connectionError:
          return "Can't reach the server. Check your internet connection.";
        case DioExceptionType.cancel:
          return 'Request cancelled.';
        default:
          return "Can't reach the server. Please try again.";
      }
    }
    // Server responded with an error. Prefer its `detail` field.
    final data = response.data;
    if (data is Map && data['detail'] is String) {
      return data['detail'] as String;
    }
    switch (response.statusCode) {
      case 400:
        return 'That request looks invalid. Please check your details.';
      case 401:
        return 'Please sign in again to continue.';
      case 403:
        return "You don't have permission for that action.";
      case 404:
        return 'The thing you were looking for is gone.';
      case 409:
        return 'That conflicts with existing data.';
      case 422:
        return 'Please check the details you entered.';
      case 429:
        return 'Too many requests. Please slow down.';
      case 500:
      case 502:
      case 503:
      case 504:
        return 'Server hiccup. Please try again in a moment.';
    }
    return fallback ?? 'Something went wrong. Please try again.';
  }
  if (error is FormatException) {
    return 'Got an unexpected response. Please try again.';
  }
  return fallback ?? 'Something went wrong. Please try again.';
}
