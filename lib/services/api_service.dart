import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../main.dart';

class ApiService {
  final Dio _dio = Dio();
  final _storage = const FlutterSecureStorage();

  // ✅ Updated to Railway live backend URL
  final String _baseUrl = 'https://insurencebook-production.up.railway.app';

  ApiService() {
    _dio.options.baseUrl = _baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    _dio.options.sendTimeout = const Duration(seconds: 30);
    // Follow redirects and preserve headers (fixes 307 redirect stripping Authorization)
    _dio.options.followRedirects = true;
    _dio.options.maxRedirects = 3;

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: 'access_token');
          debugPrint('DEBUG: API Request to ${options.path} - Token present: ${token != null}');
          if (token != null) {
            debugPrint('DEBUG: Attaching token: ${token.substring(0, 10)}...');
            options.headers['Authorization'] = 'Bearer $token';
          } else {
            debugPrint('DEBUG: No token found in storage for request to ${options.path}');
          }
          return handler.next(options);
        },
        onError: (e, handler) async {
          // Ignore 401s from the login endpoint (e.g. wrong password)
          if (e.response?.statusCode == 401 && !e.requestOptions.path.contains('/login')) {
            // Token expired — clear token and force re-login
            await _storage.delete(key: 'access_token');
            if (navigatorKey.currentState != null && navigatorKey.currentContext != null) {
              ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
                const SnackBar(
                  content: Text('Session expired. Please log in again.'),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                ),
              );
              navigatorKey.currentState!.pushNamedAndRemoveUntil('/login', (route) => false);
            }
          }
          return handler.next(e);
        },
      ),
    );
  }

  Dio get dio => _dio;

  Future<void> saveToken(String token) async {
    debugPrint('DEBUG: Saving token to storage: ${token.substring(0, 10)}...');
    await _storage.write(key: 'access_token', value: token);
  }

  Future<String?> getToken() async {
    final token = await _storage.read(key: 'access_token');
    debugPrint('DEBUG: Reading token from storage: ${token != null ? "${token.substring(0, 10)}..." : "null"}');
    return token;
  }

  Future<void> clearToken() async {
    await _storage.delete(key: 'access_token');
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.read(key: 'access_token');
    return token != null;
  }
}

final apiService = ApiService();
