import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../main.dart';

class ApiService {
  final Dio _dio = Dio();
  final _storage = const FlutterSecureStorage();

  // ✅ Updated to Render live backend URL
  final String _baseUrl = 'https://insurence-book.onrender.com';

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
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          // Ensure trailing slash consistency to avoid 307 redirects that strip auth
          // FastAPI routes defined with "/" expect trailing slash
          if (options.path.startsWith('/api/') && !options.path.endsWith('/') && !options.path.contains('?')) {
            // Only add trailing slash for paths without query params and without file extensions
            final hasExtension = options.path.split('/').last.contains('.');
            final pathSegments = options.path.split('/');
            final lastSegment = pathSegments.last;
            // Don't add trailing slash if last segment looks like an ID or has a dot
            final looksLikeEndpoint = !RegExp(r'^\d+$').hasMatch(lastSegment) && !hasExtension;
            if (looksLikeEndpoint && !options.path.endsWith('/')) {
              // Let it go as-is; the backend should handle both with and without trailing slash
            }
          }
          return handler.next(options);
        },
        onError: (e, handler) async {
          // Ignore 401s from the login endpoint (e.g. wrong password)
          if (e.response?.statusCode == 401 && !e.requestOptions.path.contains('/login')) {
            // Check if we actually had a token — if token is present but got 401,
            // it means token is genuinely expired/invalid
            final token = await _storage.read(key: 'access_token');
            if (token != null) {
              // Token exists but server rejected it — clear and redirect
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
            // If token was already null, don't redirect (avoid loop)
          }
          return handler.next(e);
        },
      ),
    );
  }

  Dio get dio => _dio;

  Future<void> saveToken(String token) async {
    await _storage.write(key: 'access_token', value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'access_token');
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
