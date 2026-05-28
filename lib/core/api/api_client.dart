import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../config/app_config.dart';
import '../storage/secure_storage.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: AppConfig.baseUrl,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(seconds: 30),
    headers: {'Content-Type': 'application/json'},
  ));

  dio.interceptors.add(_AuthInterceptor(ref, dio));
  dio.interceptors.add(PrettyDioLogger(
    requestHeader: false,
    requestBody: true,
    responseBody: true,
    error: true,
    compact: true,
  ));

  return dio;
});

class _AuthInterceptor extends Interceptor {
  final Ref _ref;
  final Dio _dio;

  /// Endpoints the interceptor must NOT try to refresh against — refreshing on
  /// a failed login would loop forever and clobber the user-facing error.
  static const _skipRefreshPaths = {
    '/auth/login',
    '/auth/register',
    '/auth/refresh',
  };

  /// Single in-flight refresh shared by all concurrent 401s. Without this,
  /// 5 parallel requests would each kick off a refresh; only the first would
  /// succeed (the others would arrive with a stale rotated refresh token).
  Future<bool>? _refreshInFlight;

  _AuthInterceptor(this._ref, this._dio);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await SecureStorage.getToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final response = err.response;
    final request = err.requestOptions;

    // Only 401s on protected endpoints are recoverable. Anything else flows
    // straight through to the caller.
    final isAuthError = response?.statusCode == 401;
    final isRefreshableRoute = !_skipRefreshPaths.any((p) => request.path.endsWith(p));
    final hasAlreadyRetried = request.extra['_retriedAfterRefresh'] == true;

    if (!isAuthError || !isRefreshableRoute || hasAlreadyRetried) {
      handler.next(err);
      return;
    }

    // Coalesce concurrent refreshes so only one network call hits /auth/refresh.
    final refreshed = await (_refreshInFlight ??= _runRefresh());
    _refreshInFlight = null;

    if (!refreshed) {
      // Refresh failed — session is genuinely dead. Clear storage and let the
      // router redirect to /login.
      await SecureStorage.clearAll();
      try {
        // forceLogout will try refresh once more, find nothing, and clear state.
        await _ref.read(authNotifierProvider.notifier).forceLogout();
      } catch (_) {}
      handler.next(err);
      return;
    }

    // Retry the original request with the new token.
    try {
      final newToken = await SecureStorage.getToken();
      final retried = await _dio.fetch<dynamic>(
        request.copyWith(
          headers: {
            ...request.headers,
            if (newToken != null) 'Authorization': 'Bearer $newToken',
          },
          extra: {...request.extra, '_retriedAfterRefresh': true},
        ),
      );
      handler.resolve(retried);
    } catch (e) {
      if (e is DioException) {
        handler.next(e);
      } else {
        handler.next(err);
      }
    }
  }

  Future<bool> _runRefresh() async {
    final stored = await SecureStorage.getRefreshToken();
    if (stored == null) return false;
    try {
      final res = await _dio.post(
        '/auth/refresh',
        data: {'refresh_token': stored},
        options: Options(headers: {'Authorization': null}),
      );
      final data = res.data as Map<String, dynamic>?;
      if (data == null) return false;
      final access = (data['access_token'] ?? data['token'])?.toString();
      if (access == null || access.isEmpty) return false;
      await SecureStorage.saveToken(access);
      final newRefresh = data['refresh_token']?.toString();
      if (newRefresh != null && newRefresh.isNotEmpty) {
        await SecureStorage.saveRefreshToken(newRefresh);
      }
      return true;
    } catch (_) {
      return false;
    }
  }
}

String apiErrorMessage(DioException e) {
  final data = e.response?.data;
  if (data is Map && data['detail'] != null) return data['detail'].toString();
  return e.message ?? 'An error occurred. Please try again.';
}
