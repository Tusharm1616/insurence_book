import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';

class AuthState {
  final UserProfile? user;
  final bool isLoading;
  final String? error;

  AuthState({this.user, this.isLoading = false, this.error});

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

  Future<void> login(String username, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await apiService.dio.post('/auth/login', data: {
        'username': username,
        'password': password,
      });
      
      final token = response.data['access_token'];
      await apiService.saveToken(token);
      
      // For now, mock the user profile fetch or get from JWT
      final user = UserProfile(
        id: 1, 
        username: username, 
        fullName: 'Agent Name', 
        role: 'agent'
      );
      
      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Login failed');
    }
  }

  Future<void> logout() async {
    await apiService.clearToken();
    state = AuthState();
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);
