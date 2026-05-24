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

  dio.interceptors.add(_AuthInterceptor(ref));
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
  _AuthInterceptor(this._ref);

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
    if (err.response?.statusCode == 401) {
      await SecureStorage.clearAll();
      try {
        // Reset auth state so router redirects to login immediately
        await _ref.read(authNotifierProvider.notifier).forceLogout();
      } catch (_) {}
    }
    handler.next(err);
  }
}

String apiErrorMessage(DioException e) {
  final data = e.response?.data;
  if (data is Map && data['detail'] != null) return data['detail'].toString();
  return e.message ?? 'An error occurred. Please try again.';
}
