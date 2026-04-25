import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  final Dio _dio = Dio();
  final _storage = const FlutterSecureStorage();
  
  // Use 10.0.2.2 for Android Emulator to access localhost on host machine
  final String _baseUrl = 'http://10.0.2.2:8000';

  ApiService() {
    _dio.options.baseUrl = _baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 10);
    _dio.options.receiveTimeout = const Duration(seconds: 10);
    
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'access_token');
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onError: (e, handler) async {
        if (e.response?.statusCode == 401) {
          // To Do: Implement refresh token logic or logout
        }
        return handler.next(e);
      },
    ));
  }

  Dio get dio => _dio;
  
  Future<void> saveToken(String token) async {
    await _storage.write(key: 'access_token', value: token);
  }
  
  Future<void> clearToken() async {
    await _storage.delete(key: 'access_token');
  }
}

final apiService = ApiService();
