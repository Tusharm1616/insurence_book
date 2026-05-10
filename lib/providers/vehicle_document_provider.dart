import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

class VehicleDocumentState {
  final bool isLoading;
  final String? error;
  final Map<String, dynamic>? data;

  VehicleDocumentState({
    this.isLoading = false,
    this.error,
    this.data,
  });

  VehicleDocumentState copyWith({
    bool? isLoading,
    String? error,
    Map<String, dynamic>? data,
    bool clearError = false,
  }) {
    return VehicleDocumentState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      data: data ?? this.data,
    );
  }
}

class VehicleDocumentNotifier extends Notifier<VehicleDocumentState> {
  @override
  VehicleDocumentState build() {
    return VehicleDocumentState();
  }

  Future<void> fetchDocumentStatus(String regNo) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final response = await apiService.dio.get('/api/vehicle/document-status?reg_no=$regNo');
      state = state.copyWith(isLoading: false, data: response.data);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Network error occurred. Please try again.',
      );
    }
  }
  
  void clear() {
    state = VehicleDocumentState();
  }
}

final vehicleDocumentProvider = NotifierProvider<VehicleDocumentNotifier, VehicleDocumentState>(
  VehicleDocumentNotifier.new,
);
