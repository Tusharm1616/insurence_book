import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/policy_v2_model.dart';
import '../services/api_service.dart';

// ── Response Models ────────────────────────────────────────────────────────

class PolicyV2ListResponse {
  final int total;
  final int page;
  final int pages;
  final List<PolicyV2> data;

  PolicyV2ListResponse({
    required this.total,
    required this.page,
    required this.pages,
    required this.data,
  });

  factory PolicyV2ListResponse.fromJson(Map<String, dynamic> json) {
    return PolicyV2ListResponse(
      total: json['total'] ?? 0,
      page: json['page'] ?? 1,
      pages: json['pages'] ?? 1,
      data: (json['data'] as List<dynamic>? ?? [])
          .map((e) => PolicyV2.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

// ── Provider State ─────────────────────────────────────────────────────────

class PolicyV2State {
  final PolicyV2ListResponse? listResponse;
  final PolicyV2? currentPolicy;
  final bool isSubmitting;
  final String? error;

  PolicyV2State({
    this.listResponse,
    this.currentPolicy,
    this.isSubmitting = false,
    this.error,
  });

  PolicyV2State copyWith({
    PolicyV2ListResponse? listResponse,
    PolicyV2? currentPolicy,
    bool? isSubmitting,
    String? error,
    bool clearError = false,
    bool clearCurrentPolicy = false,
  }) {
    return PolicyV2State(
      listResponse: listResponse ?? this.listResponse,
      currentPolicy: clearCurrentPolicy ? null : (currentPolicy ?? this.currentPolicy),
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ── Notifier ───────────────────────────────────────────────────────────────

class PolicyV2Notifier extends AsyncNotifier<PolicyV2State> {
  static const String _basePath = '/api/policies-v2/';
  static const Duration _timeout = Duration(seconds: 30);

  @override
  Future<PolicyV2State> build() async {
    return PolicyV2State();
  }

  /// Creates a new policy. Returns the created [PolicyV2] on success.
  Future<PolicyV2> createPolicy(Map<String, dynamic> data) async {
    state = AsyncData(
      (state.value ?? PolicyV2State()).copyWith(isSubmitting: true, clearError: true),
    );
    try {
      final response = await apiService.dio
          .post(_basePath, data: data)
          .timeout(_timeout);

      final created = PolicyV2.fromJson(response.data as Map<String, dynamic>);

      state = AsyncData(
        (state.value ?? PolicyV2State()).copyWith(
          isSubmitting: false,
          currentPolicy: created,
        ),
      );
      return created;
    } on DioException catch (e) {
      final errorMessage = _extractErrorMessage(e);
      state = AsyncData(
        (state.value ?? PolicyV2State()).copyWith(
          isSubmitting: false,
          error: errorMessage,
        ),
      );
      throw Exception(errorMessage);
    } catch (e) {
      final errorMessage = e.toString().contains('TimeoutException')
          ? 'Request timed out. Please try again.'
          : 'An unexpected error occurred.';
      state = AsyncData(
        (state.value ?? PolicyV2State()).copyWith(
          isSubmitting: false,
          error: errorMessage,
        ),
      );
      throw Exception(errorMessage);
    }
  }

  /// Fetches paginated list of policies.
  Future<PolicyV2ListResponse> fetchPolicies({int page = 1, int limit = 20}) async {
    state = const AsyncLoading();
    try {
      final response = await apiService.dio.get(
        _basePath,
        queryParameters: {'page': page, 'limit': limit},
      ).timeout(_timeout);

      final listResponse = PolicyV2ListResponse.fromJson(
        response.data as Map<String, dynamic>,
      );

      state = AsyncData(
        (state.value ?? PolicyV2State()).copyWith(
          listResponse: listResponse,
          clearError: true,
        ),
      );
      return listResponse;
    } on DioException catch (e) {
      final errorMessage = _extractErrorMessage(e);
      state = AsyncData(
        PolicyV2State(error: errorMessage),
      );
      throw Exception(errorMessage);
    } catch (e) {
      final errorMessage = e.toString().contains('TimeoutException')
          ? 'Request timed out. Please try again.'
          : 'Failed to load policies.';
      state = AsyncData(
        PolicyV2State(error: errorMessage),
      );
      throw Exception(errorMessage);
    }
  }

  /// Fetches a single policy by ID.
  Future<PolicyV2> fetchPolicyDetail(String id) async {
    state = const AsyncLoading();
    try {
      final response = await apiService.dio
          .get('$_basePath$id')
          .timeout(_timeout);

      final policy = PolicyV2.fromJson(response.data as Map<String, dynamic>);

      state = AsyncData(
        (state.value ?? PolicyV2State()).copyWith(
          currentPolicy: policy,
          clearError: true,
        ),
      );
      return policy;
    } on DioException catch (e) {
      final errorMessage = _extractErrorMessage(e);
      state = AsyncData(
        (state.value ?? PolicyV2State()).copyWith(error: errorMessage),
      );
      throw Exception(errorMessage);
    } catch (e) {
      final errorMessage = e.toString().contains('TimeoutException')
          ? 'Request timed out. Please try again.'
          : 'Failed to load policy details.';
      state = AsyncData(
        (state.value ?? PolicyV2State()).copyWith(error: errorMessage),
      );
      throw Exception(errorMessage);
    }
  }

  /// Updates an existing policy. Returns the updated [PolicyV2].
  Future<PolicyV2> updatePolicy(String id, Map<String, dynamic> data) async {
    state = AsyncData(
      (state.value ?? PolicyV2State()).copyWith(isSubmitting: true, clearError: true),
    );
    try {
      final response = await apiService.dio
          .put('$_basePath$id', data: data)
          .timeout(_timeout);

      final updated = PolicyV2.fromJson(response.data as Map<String, dynamic>);

      state = AsyncData(
        (state.value ?? PolicyV2State()).copyWith(
          isSubmitting: false,
          currentPolicy: updated,
        ),
      );
      return updated;
    } on DioException catch (e) {
      final errorMessage = _extractErrorMessage(e);
      state = AsyncData(
        (state.value ?? PolicyV2State()).copyWith(
          isSubmitting: false,
          error: errorMessage,
        ),
      );
      throw Exception(errorMessage);
    } catch (e) {
      final errorMessage = e.toString().contains('TimeoutException')
          ? 'Request timed out. Please try again.'
          : 'Failed to update policy.';
      state = AsyncData(
        (state.value ?? PolicyV2State()).copyWith(
          isSubmitting: false,
          error: errorMessage,
        ),
      );
      throw Exception(errorMessage);
    }
  }

  /// Soft-deletes a policy by ID.
  Future<void> deletePolicy(String id) async {
    state = AsyncData(
      (state.value ?? PolicyV2State()).copyWith(isSubmitting: true, clearError: true),
    );
    try {
      await apiService.dio
          .delete('$_basePath$id')
          .timeout(_timeout);

      // Remove from list if present
      final currentList = state.value?.listResponse;
      PolicyV2ListResponse? updatedList;
      if (currentList != null) {
        updatedList = PolicyV2ListResponse(
          total: currentList.total - 1,
          page: currentList.page,
          pages: currentList.pages,
          data: currentList.data.where((p) => p.id != id).toList(),
        );
      }

      state = AsyncData(
        PolicyV2State(
          listResponse: updatedList,
          isSubmitting: false,
        ),
      );
    } on DioException catch (e) {
      final errorMessage = _extractErrorMessage(e);
      state = AsyncData(
        (state.value ?? PolicyV2State()).copyWith(
          isSubmitting: false,
          error: errorMessage,
        ),
      );
      throw Exception(errorMessage);
    } catch (e) {
      final errorMessage = e.toString().contains('TimeoutException')
          ? 'Request timed out. Please try again.'
          : 'Failed to delete policy.';
      state = AsyncData(
        (state.value ?? PolicyV2State()).copyWith(
          isSubmitting: false,
          error: errorMessage,
        ),
      );
      throw Exception(errorMessage);
    }
  }

  /// Uploads a PDF file to a policy.
  /// [type] must be 'current' or 'last_year'.
  Future<String> uploadPdf(String id, File file, String type) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split(Platform.pathSeparator).last,
        ),
      });

      final response = await apiService.dio.post(
        '$_basePath$id/upload-pdf',
        data: formData,
        queryParameters: {'type': type},
        options: Options(
          contentType: 'multipart/form-data',
          sendTimeout: _timeout,
          receiveTimeout: _timeout,
        ),
      ).timeout(_timeout);

      final responseData = response.data as Map<String, dynamic>;
      final url = type == 'current'
          ? responseData['policy_pdf_url'] as String? ?? ''
          : responseData['last_year_policy_pdf_url'] as String? ?? '';

      // Update current policy state with new URL
      final currentPolicy = state.value?.currentPolicy;
      if (currentPolicy != null) {
        final updatedPolicy = PolicyV2.fromJson({
          ...currentPolicy.toJson(),
          if (type == 'current') 'policy_pdf_url': url,
          if (type == 'last_year') 'last_year_policy_pdf_url': url,
        });
        state = AsyncData(
          (state.value ?? PolicyV2State()).copyWith(currentPolicy: updatedPolicy),
        );
      }

      return url;
    } on DioException catch (e) {
      final errorMessage = _extractErrorMessage(e);
      debugPrint('PDF upload failed: $errorMessage');
      throw Exception(errorMessage);
    } catch (e) {
      final errorMessage = e.toString().contains('TimeoutException')
          ? 'Upload timed out. Please try again.'
          : 'Failed to upload PDF.';
      debugPrint('PDF upload failed: $errorMessage');
      throw Exception(errorMessage);
    }
  }

  /// Extracts a user-friendly error message from a DioException.
  String _extractErrorMessage(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return 'Request timed out. Please try again.';
    }

    if (e.type == DioExceptionType.connectionError) {
      return 'Unable to connect. Please check your internet connection.';
    }

    final responseData = e.response?.data;
    if (responseData is Map<String, dynamic>) {
      // Handle detail as string
      if (responseData['detail'] is String) {
        return responseData['detail'] as String;
      }
      // Handle detail as list of validation errors
      if (responseData['detail'] is List) {
        final errors = responseData['detail'] as List;
        if (errors.isNotEmpty) {
          final firstError = errors.first;
          if (firstError is Map<String, dynamic>) {
            return firstError['message'] as String? ??
                firstError['msg'] as String? ??
                'Validation error.';
          }
          return firstError.toString();
        }
      }
    }

    switch (e.response?.statusCode) {
      case 400:
        return 'Invalid request. Please check your input.';
      case 401:
        return 'Session expired. Please log in again.';
      case 404:
        return 'Resource not found.';
      case 409:
        return 'A policy with this number already exists.';
      case 422:
        return 'Validation error. Please check your input.';
      case 500:
        return 'Server error. Please try again later.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}

// ── Provider Registration ──────────────────────────────────────────────────

final policyV2Provider =
    AsyncNotifierProvider<PolicyV2Notifier, PolicyV2State>(
  PolicyV2Notifier.new,
);
