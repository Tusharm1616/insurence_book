import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import 'package:dio/dio.dart';

class AuthState {
  final UserProfile? user;
  final bool isLoading;
  final String? error;

  AuthState({this.user, this.isLoading = false, this.error});

  bool get isAuthenticated => user != null;

  AuthState copyWith({UserProfile? user, bool? isLoading, String? error}) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// ── Helper: extract a clean error message from DioException ──────────────────
String _dioErrorMessage(DioException e, String fallback) {
  if (e.response != null) {
    final data = e.response?.data;
    if (data is Map<String, dynamic> && data.containsKey('detail')) {
      return data['detail'].toString();
    }
    if (data is String && data.isNotEmpty) return data;
    return '$fallback (${e.response?.statusCode})';
  }
  // No response — network-level error
  switch (e.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return 'Connection timed out. Please check your internet and try again.';
    case DioExceptionType.connectionError:
      return 'No internet connection. Please check your network.';
    default:
      return 'Network error. Please try again.';
  }
}

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    Future.microtask(() => initialize());
    return AuthState();
  }

  Future<void> initialize() async {
    final token = await apiService.getToken();
    if (token == null) return;

    state = state.copyWith(isLoading: true);
    try {
      final response = await apiService.dio.get('/api/auth/profile');
      final agentData = response.data;
      final user = UserProfile(
        id: agentData['id'],
        username: agentData['email'],
        fullName: agentData['name'],
        role: 'agent',
        email: agentData['email'],
      );
      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      await apiService.clearToken();
      state = AuthState();
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await apiService.dio.post('/api/auth/login', data: {
        'email': email,
        'password': password,
      });

      final token = response.data['token'];
      await apiService.saveToken(token);

      final agentData = response.data['agent'];
      final user = UserProfile(
        id: agentData['id'],
        username: agentData['email'],
        fullName: agentData['name'],
        role: 'agent',
      );

      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      final msg = e is DioException
          ? _dioErrorMessage(e, 'Login failed')
          : e.toString();
      state = state.copyWith(isLoading: false, error: msg);
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String phone,
    required String licenseNo,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await apiService.dio.post('/api/auth/register', data: {
        'name': name,
        'email': email,
        'phone': phone,
        'license_no': licenseNo,
        'password': password,
      });
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      final msg = e is DioException
          ? _dioErrorMessage(e, 'Registration failed')
          : e.toString();
      state = state.copyWith(isLoading: false, error: msg);
      return false;
    }
  }

  Future<bool> forgotPassword(String email) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await apiService.dio.post('/api/auth/forgot-password', data: {
        'email': email,
      });
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to send reset link');
      return false;
    }
  }

  Future<void> logout() async {
    await apiService.clearToken();
    state = AuthState();
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
