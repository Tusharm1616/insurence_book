import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

class ExpiringPolicy {
  final int id;
  final String policyNumber;
  final String policyType;
  final String? insurerName;
  final double? premiumAmount;
  final String? expiryDate;
  final int daysRemaining;
  final String customerName;
  final String customerPhone;

  ExpiringPolicy({
    required this.id,
    required this.policyNumber,
    required this.policyType,
    this.insurerName,
    this.premiumAmount,
    this.expiryDate,
    required this.daysRemaining,
    required this.customerName,
    required this.customerPhone,
  });

  factory ExpiringPolicy.fromJson(Map<String, dynamic> json) {
    return ExpiringPolicy(
      id: json['policy_id'],
      policyNumber: json['policy_number'],
      policyType: json['policy_type'],
      insurerName: json['insurer_name'],
      premiumAmount: json['premium_amount']?.toDouble(),
      expiryDate: json['expiry_date'],
      daysRemaining: json['days_remaining'],
      customerName: json['customer_full_name'],
      customerPhone: json['customer_phone_number'],
    );
  }
}

class ExpiringPoliciesState {
  final List<ExpiringPolicy> policies;
  final bool isLoading;
  final bool hasMore;
  final String? error;
  final int page;
  
  ExpiringPoliciesState({
    this.policies = const [],
    this.isLoading = true,
    this.hasMore = true,
    this.error,
    this.page = 1,
  });
  
  ExpiringPoliciesState copyWith({
    List<ExpiringPolicy>? policies,
    bool? isLoading,
    bool? hasMore,
    String? error,
    int? page,
  }) {
    return ExpiringPoliciesState(
      policies: policies ?? this.policies,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: error ?? this.error,
      page: page ?? this.page,
    );
  }
}

class ExpiringPoliciesNotifier extends Notifier<ExpiringPoliciesState> {
  @override
  ExpiringPoliciesState build() {
    return ExpiringPoliciesState();
  }

  Future<void> fetchInitial(int days) async {
    state = state.copyWith(isLoading: true, error: null, page: 1, hasMore: true);
    try {
      final res = await apiService.dio.get('/dashboard/expiring-list', queryParameters: {
        'days': days,
        'page': 1,
        'limit': 20,
      });
      final List data = res.data['items'];
      final policies = data.map((e) => ExpiringPolicy.fromJson(e)).toList();
      state = state.copyWith(
        policies: policies,
        isLoading: false,
        hasMore: policies.length == 20,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> fetchMore(int days) async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final nextPage = state.page + 1;
      final res = await apiService.dio.get('/dashboard/expiring-list', queryParameters: {
        'days': days,
        'page': nextPage,
        'limit': 20,
      });
      final List data = res.data['items'];
      final newPolicies = data.map((e) => ExpiringPolicy.fromJson(e)).toList();
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

final expiringPoliciesProvider = NotifierProvider<ExpiringPoliciesNotifier, ExpiringPoliciesState>(
  ExpiringPoliciesNotifier.new,
);
