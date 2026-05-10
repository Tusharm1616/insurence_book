import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../models/vehicle_document_model.dart';

// ── Providers ──────────────────────────────────────────────────────────────

/// Full list of vehicle documents for the current agent
final vehicleDocsProvider = AsyncNotifierProvider<VehicleDocsNotifier, List<VehicleDoc>>(
  VehicleDocsNotifier.new,
);

/// Dashboard summary counts
final vehicleDocsSummaryProvider = FutureProvider<VehicleDocSummary>((ref) async {
  final response = await apiService.dio.get('/api/vehicle-docs/summary');
  return VehicleDocSummary.fromJson(response.data as Map<String, dynamic>);
});

// ── Notifier ───────────────────────────────────────────────────────────────
class VehicleDocsNotifier extends AsyncNotifier<List<VehicleDoc>> {
  @override
  Future<List<VehicleDoc>> build() => _fetchAll();

  Future<List<VehicleDoc>> _fetchAll({String? search, String? status}) async {
    final params = <String, String>{};
    if (search != null && search.isNotEmpty) params['search'] = search;
    if (status != null && status.isNotEmpty) params['status'] = status;
    final response = await apiService.dio.get('/api/vehicle-docs/', queryParameters: params);
    final data = response.data as List<dynamic>;
    return data.map((e) => VehicleDoc.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> refresh({String? search, String? status}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchAll(search: search, status: status));
  }

  Future<VehicleDoc> addVehicle(Map<String, dynamic> payload) async {
    final response = await apiService.dio.post('/api/vehicle-docs/', data: payload);
    final newDoc   = VehicleDoc.fromJson(response.data as Map<String, dynamic>);
    state = AsyncData([newDoc, ...state.value ?? []]);
    return newDoc;
  }

  Future<VehicleDoc> updateVehicle(int id, Map<String, dynamic> payload) async {
    final response = await apiService.dio.put('/api/vehicle-docs/$id', data: payload);
    final updated  = VehicleDoc.fromJson(response.data as Map<String, dynamic>);
    state = AsyncData(
      (state.value ?? []).map((d) => d.id == id ? updated : d).toList(),
    );
    return updated;
  }

  Future<void> deleteVehicle(int id) async {
    await apiService.dio.delete('/api/vehicle-docs/$id');
    state = AsyncData((state.value ?? []).where((d) => d.id != id).toList());
  }

  /// Returns: {status: 'sent'|'manual'|'no_action', message: ..., [whatsapp_message: ...], [mobile: ...]}
  Future<Map<String, dynamic>> sendReminder(int id) async {
    final response = await apiService.dio.post('/api/vehicle-docs/$id/send-reminder');
    return response.data as Map<String, dynamic>;
  }
}

// ── Legacy provider (kept so old VehicleDocumentScreen still compiles) ─────
class VehicleDocumentState {
  final bool isLoading;
  final String? error;
  final Map<String, dynamic>? data;

  VehicleDocumentState({this.isLoading = false, this.error, this.data});

  VehicleDocumentState copyWith({bool? isLoading, String? error, Map<String, dynamic>? data, bool clearError = false}) {
    return VehicleDocumentState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      data: data ?? this.data,
    );
  }
}

class VehicleDocumentNotifier extends Notifier<VehicleDocumentState> {
  @override
  VehicleDocumentState build() => VehicleDocumentState();

  Future<void> fetchDocumentStatus(String regNo) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await apiService.dio.get('/api/vehicle/document-status?reg_no=$regNo');
      state = state.copyWith(isLoading: false, data: response.data as Map<String, dynamic>);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Network error occurred. Please try again.');
    }
  }

  void clear() => state = VehicleDocumentState();
}

final vehicleDocumentProvider = NotifierProvider<VehicleDocumentNotifier, VehicleDocumentState>(
  VehicleDocumentNotifier.new,
);
