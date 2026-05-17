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
    try {
      final user = await _repo.getMe();
      state = state.copyWith(user: user);
    } catch (_) {
      await SecureStorage.clearAll();
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final data = await _repo.login(LoginRequest(email: email, password: password));
      await SecureStorage.saveToken(data['access_token'] as String);
      final user = await _repo.getMe();
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
      await SecureStorage.saveToken(data['access_token'] as String);
      final user = await _repo.getMe();
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
    state = state.copyWith(user: updated);
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.watch(authRepositoryProvider));
});
