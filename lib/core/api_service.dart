import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  late Dio _dio;
  final _baseUrl = 'http://localhost:8000'; // Update with your backend URL

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Add auth interceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _getAuthToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            // Token expired, clear storage
            await _clearAuthToken();
            // You can navigate to login screen here
          }
          return handler.next(error);
        },
      ),
    );
  }

  Future<Response> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters);
    } catch (e) {
      throw Exception('Failed to make GET request: $e');
    }
  }

  Future<Response> post(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.post(path, data: data, queryParameters: queryParameters);
    } catch (e) {
      throw Exception('Failed to make POST request: $e');
    }
  }

  Future<Response> put(String path, {dynamic data, Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.put(path, data: data, queryParameters: queryParameters);
    } catch (e) {
      throw Exception('Failed to make PUT request: $e');
    }
  }

  Future<Response> delete(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      return await _dio.delete(path, queryParameters: queryParameters);
    } catch (e) {
      throw Exception('Failed to make DELETE request: $e');
    }
  }

  Future<String?> _getAuthToken() async {
    try {
      return await FlutterSecureStorage().read(key: 'auth_token');
    } catch (e) {
      return null;
    }
  }

  Future<void> _clearAuthToken() async {
    try {
      await FlutterSecureStorage().delete(key: 'auth_token');
    } catch (e) {
      // Handle error
    }
  }
}

class InterceptorsWrapper {
  final Function(RequestOptions, RequestInterceptorHandler) onRequest;
  final Function(DioException, ErrorInterceptorHandler) onError;

  InterceptorsWrapper({
    required this.onRequest,
    required this.onError,
  });

  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    onRequest(options, handler);
  }

  void onError(DioException error, ErrorInterceptorHandler handler) {
    onError(error, handler);
  }
}

typedef RequestInterceptorHandler = void Function(RequestOptions options);
typedef ErrorInterceptorHandler = void Function(DioException error);
