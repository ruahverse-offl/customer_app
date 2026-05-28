import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/secure_storage.dart';
import '../data/auth_models.dart';
import '../data/auth_repository.dart';

class AuthState {
  final AuthUser? user;
  final bool isLoading;
  final String? error;
  final bool isRestoring;

  const AuthState({this.user, this.isLoading = false, this.error, this.isRestoring = false});
  AuthState copyWith({AuthUser? user, bool? isLoading, String? error, bool clearUser = false, bool? isRestoring}) => AuthState(
    user: clearUser ? null : (user ?? this.user),
    isLoading: isLoading ?? this.isLoading,
    error: error,
    isRestoring: isRestoring ?? this.isRestoring,
  );
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repo;

  AuthNotifier(this._repo) : super(const AuthState(isRestoring: true)) {
    _restore();
  }

  Future<void> _restore() async {
    final token = await SecureStorage.getToken();
    if (token == null) {
      state = const AuthState();
      return;
    }

    // Restore from cache immediately so the router unblocks without waiting
    // for the network. If cache is missing but the token is present, fall
    // through to a network fetch — this keeps the user logged in across a
    // cache wipe / app upgrade.
    //
    // Note: `roleCode == 'PUBLIC'` USED to be treated as "anonymous, log out"
    // but on this backend PUBLIC is the role assigned to every signed-up
    // customer (see auth_service.register()). Treating it as a logged-out
    // sentinel was wrongly wiping legitimate sessions on every cold start.
    final cachedJson = await SecureStorage.getUserJson();
    if (cachedJson != null) {
      try {
        final user = AuthUser.fromJson(jsonDecode(cachedJson) as Map<String, dynamic>);
        state = AuthState(user: user); // isRestoring=false — unblocks router
      } catch (_) {
        // Corrupted cache — fall through to a network fetch.
      }
    }

    // Background validation. We only react to a hard 401 (session genuinely
    // dead — the dio interceptor has already tried refresh by then). Any
    // other failure (network, server down, partial profile data) leaves the
    // cached user in place so the app stays usable offline.
    try {
      final user = await _repo.getMe();
      // Only overwrite the cached user if the response carries real profile
      // fields. /auth/me/permissions returns role info only — id/email/name
      // come back empty, and overwriting with that would erase the cache.
      if (user.id.isNotEmpty && user.email.isNotEmpty) {
        await SecureStorage.saveUserJson(jsonEncode(user.toJson()));
        state = state.copyWith(user: user);
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        // Session is genuinely dead — the interceptor already attempted refresh.
        await SecureStorage.clearAll();
        state = const AuthState();
      }
      // Any other error (no internet, timeout, server down): keep cached user
      // logged in. They can still see the offline-tolerant parts of the app.
    } catch (_) {
      // Keep cached user on unknown errors.
    }
  }

  /// Silently renews tokens using the stored refresh token.
  /// Saves both new access token and rotated refresh token.
  /// Returns true on success.
  Future<bool> _tryRefreshToken() async {
    final stored = await SecureStorage.getRefreshToken();
    if (stored == null) return false;
    try {
      final tokens = await _repo.refreshToken(stored);
      if (tokens.accessToken.isEmpty) return false;
      await SecureStorage.saveToken(tokens.accessToken);
      if (tokens.refreshToken != null) await SecureStorage.saveRefreshToken(tokens.refreshToken!);
      return true;
    } catch (_) {
      return false;
    }
  }

  // Called by the API interceptor when any mid-session request returns 401
  Future<void> forceLogout() async {
    // Try silent refresh first; only hard-logout if refresh also fails
    final refreshed = await _tryRefreshToken();
    if (!refreshed) {
      await SecureStorage.clearAll();
      state = const AuthState();
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
      final refresh = data['refresh_token']?.toString();
      await SecureStorage.saveToken(token);
      if (refresh != null) await SecureStorage.saveRefreshToken(refresh);
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
      final refresh = data['refresh_token']?.toString();
      await SecureStorage.saveToken(token);
      if (refresh != null) await SecureStorage.saveRefreshToken(refresh);
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
    await SecureStorage.clearAll(); // clears token, refresh_token, user json
    state = const AuthState();
  }

  /// Permanently delete the user's account. Requires password re-entry.
  /// On success, clears all local session state — the caller should redirect
  /// to the login screen.
  Future<void> deleteAccount({required String password, String? reason}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repo.deleteAccount(password: password, reason: reason);
      await SecureStorage.clearAll();
      state = const AuthState();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  void updateLocalUser(AuthUser updated) {
    _persistUser(updated);
    state = state.copyWith(user: updated);
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});
