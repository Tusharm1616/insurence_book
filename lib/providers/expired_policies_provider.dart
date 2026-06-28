import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

class ExpiredPolicy {
  final String id;
  final String policyNumber;
  final String policyType;
  final String? insurerName;
  final double? premiumAmount;
  final String? expiryDate;
  final int daysOverdue;
  final String customerName;
  final String customerPhone;

  ExpiredPolicy({
    required this.id,
    required this.policyNumber,
    required this.policyType,
    this.insurerName,
    this.premiumAmount,
    this.expiryDate,
    required this.daysOverdue,
    required this.customerName,
    required this.customerPhone,
  });

  factory ExpiredPolicy.fromJson(Map<String, dynamic> json) {
    return ExpiredPolicy(
      id: json['policy_id'].toString(),
      policyNumber: json['policy_number'],
      policyType: json['policy_type'],
      insurerName: json['insurer_name'],
      premiumAmount: json['premium_amount']?.toDouble(),
      expiryDate: json['expiry_date'],
      daysOverdue: json['days_overdue'],
      customerName: json['customer_full_name'],
      customerPhone: json['customer_phone_number'],
    );
  }
}

class ExpiredPoliciesState {
  final List<ExpiredPolicy> policies;
  final bool isLoading;
  final bool hasMore;
  final String? error;
  final int page;

  ExpiredPoliciesState({
    this.policies = const [],
    this.isLoading = true,
    this.hasMore = true,
    this.error,
    this.page = 1,
  });

  ExpiredPoliciesState copyWith({
    List<ExpiredPolicy>? policies,
    bool? isLoading,
    bool? hasMore,
    String? error,
    int? page,
  }) {
    return ExpiredPoliciesState(
      policies: policies ?? this.policies,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: error ?? this.error,
      page: page ?? this.page,
    );
  }
}

class ExpiredPoliciesNotifier extends Notifier<ExpiredPoliciesState> {
  @override
  ExpiredPoliciesState build() => ExpiredPoliciesState();

  Future<void> fetchInitial() async {
    state = state.copyWith(isLoading: true, error: null, page: 1, hasMore: true, policies: []);
    try {
      final res = await apiService.dio.get('/api/dashboard/expired-list', queryParameters: {
        'page': 1,
        'limit': 20,
      });
      final List data = res.data['items'];
      final policies = data.map((e) => ExpiredPolicy.fromJson(e)).toList();
      state = state.copyWith(
        policies: policies,
        isLoading: false,
        hasMore: policies.length == 20,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> fetchMore() async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final nextPage = state.page + 1;
      final res = await apiService.dio.get('/api/dashboard/expired-list', queryParameters: {
        'page': nextPage,
        'limit': 20,
      });
      final List data = res.data['items'];
      final newPolicies = data.map((e) => ExpiredPolicy.fromJson(e)).toList();
      state = state.copyWith(
        policies: [...state.policies, ...newPolicies],
        isLoading: false,
        page: nextPage,
        hasMore: newPolicies.length == 20,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final expiredPoliciesListProvider =
    NotifierProvider<ExpiredPoliciesNotifier, ExpiredPoliciesState>(
  ExpiredPoliciesNotifier.new,
);

/// FutureProvider for the expired count shown on the dashboard stat card
final expiredCountProvider = FutureProvider<int>((ref) async {
  final res = await apiService.dio.get('/api/dashboard/expired-count');
  return res.data['count'] ?? 0;
});
