import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import 'auth_models.dart';

class AuthRepository {
  final Dio _dio;
  const AuthRepository(this._dio);

  Future<Map<String, dynamic>> login(LoginRequest req) async {
    final res = await _dio.post('/auth/login', data: req.toJson());
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> register(RegisterRequest req) async {
    final res = await _dio.post('/auth/register', data: req.toJson());
    return res.data as Map<String, dynamic>;
  }

  Future<AuthUser> getMe() async {
    final res = await _dio.get('/auth/me/permissions');
    final data = res.data as Map<String, dynamic>;
    return AuthUser.fromJson(data['user'] ?? data);
  }

  Future<({String accessToken, String? refreshToken})> refreshToken(String refreshToken) async {
    final res = await _dio.post('/auth/refresh', data: {'refresh_token': refreshToken});
    final data = res.data as Map<String, dynamic>;
    return (
      accessToken: (data['access_token'] ?? data['token'])?.toString() ?? '',
      refreshToken: data['refresh_token']?.toString(),
    );
  }

  Future<void> logout() async {
    await _dio.post('/auth/logout');
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _dio.post('/auth/change-password', data: {
      'current_password': currentPassword,
      'new_password': newPassword,
    });
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(dioProvider));
});
