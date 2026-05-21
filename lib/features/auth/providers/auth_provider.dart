import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/secure_storage.dart';
import '../data/auth_models.dart';
import '../data/auth_repository.dart';

class AuthState {
  final AuthUser? user;
  final bool isLoading;
  final String? error;

  const AuthState({this.user, this.isLoading = false, this.error});
  AuthState copyWith({AuthUser? user, bool? isLoading, String? error, bool clearUser = false}) => AuthState(
    user: clearUser ? null : (user ?? this.user),
    isLoading: isLoading ?? this.isLoading,
    error: error,
  );
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repo;

  AuthNotifier(this._repo) : super(const AuthState()) {
    _restore();
  }

  Future<void> _restore() async {
    final token = await SecureStorage.getToken();
    if (token == null) return;

    // Restore user from cache immediately — no network needed
    final cachedJson = await SecureStorage.getUserJson();
    if (cachedJson != null) {
      try {
        final user = AuthUser.fromJson(jsonDecode(cachedJson) as Map<String, dynamic>);
        if (user.roleCode == 'PUBLIC') {
          await SecureStorage.clearAll();
          return;
        }
        state = state.copyWith(user: user);
      } catch (_) {}
    }

    // Refresh user data in background (don't block navigation)
    try {
      final user = await _repo.getMe();
      if (user.roleCode == 'PUBLIC') {
        await SecureStorage.clearAll();
        state = const AuthState();
        return;
      }
      await SecureStorage.saveUserJson(jsonEncode(user.toJson()));
      state = state.copyWith(user: user);
    } catch (_) {
      // Network error — keep cached user. Explicit 401 is handled by API interceptor.
    }
  }

  Future<void> _persistUser(AuthUser user) async {
    await SecureStorage.saveUserJson(jsonEncode(user.toJson()));
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _repo.login(LoginRequest(email: email, password: password));
      final token = (data['token'] ?? data['access_token']).toString();
      await SecureStorage.saveToken(token);
      final raw = data['user'];
      final userMap = raw is Map<String, dynamic> ? raw : <String, dynamic>{};
      final user = AuthUser(
        id: (userMap['id'] ?? '').toString(),
        email: (userMap['email'] ?? email).toString(),
        fullName: (userMap['full_name'] ?? '').toString(),
        mobileNumber: userMap['mobile_number']?.toString(),
        roleCode: (userMap['role_code'] ?? 'CUSTOMER').toString(),
      );
      await _persistUser(user);
      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> register(String fullName, String email, String password, String mobile) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _repo.register(RegisterRequest(
        fullName: fullName,
        email: email,
        password: password,
        mobileNumber: mobile,
      ));
      final token = (data['token'] ?? data['access_token']).toString();
      await SecureStorage.saveToken(token);
      final raw = data['user'];
      final userMap = raw is Map<String, dynamic> ? raw : <String, dynamic>{};
      final user = AuthUser(
        id: (userMap['id'] ?? '').toString(),
        email: (userMap['email'] ?? email).toString(),
        fullName: (userMap['full_name'] ?? fullName).toString(),
        mobileNumber: userMap['mobile_number']?.toString(),
        roleCode: (userMap['role_code'] ?? 'CUSTOMER').toString(),
      );
      await _persistUser(user);
      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> logout() async {
    try { await _repo.logout(); } catch (_) {}
    await SecureStorage.clearAll();
    state = const AuthState();
  }

  void updateLocalUser(AuthUser updated) {
    _persistUser(updated);
    state = state.copyWith(user: updated);
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});
