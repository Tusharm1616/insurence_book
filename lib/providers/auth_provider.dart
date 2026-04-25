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

class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => AuthState();

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
        role: 'agent'
      );
      
      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      String errorMessage = 'Login failed';
      if (e is DioException) {
        if (e.response != null) {
          errorMessage = e.response?.data['detail'] ?? 'Login failed (Server Error: ${e.response?.statusCode})';
        } else {
          errorMessage = 'Network Error: Make sure backend is running';
        }
      } else {
        errorMessage = e.toString();
      }
      state = state.copyWith(isLoading: false, error: errorMessage);
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
      String errorMessage = 'Registration failed';
      if (e is DioException) {
        if (e.response != null) {
          errorMessage = e.response?.data['detail'] ?? 'Registration failed (Server Error: ${e.response?.statusCode})';
        } else {
          errorMessage = 'Network Error: Make sure backend is running';
        }
      } else {
        errorMessage = e.toString();
      }
      state = state.copyWith(isLoading: false, error: errorMessage);
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
