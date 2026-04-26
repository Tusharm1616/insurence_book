import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

class LifePolicy {
  final int id;
  final String policyNumber;
  final String? insurerName;
  final String status;
  final double? premiumAmount;
  final String? premiumDueDate;
  final String? maturityDate;
  final double? sumAssured;
  final String customerName;
  final String customerPhone;

  LifePolicy({
    required this.id,
    required this.policyNumber,
    this.insurerName,
    required this.status,
    this.premiumAmount,
    this.premiumDueDate,
    this.maturityDate,
    this.sumAssured,
    required this.customerName,
    required this.customerPhone,
  });

  factory LifePolicy.fromJson(Map<String, dynamic> json) {
    return LifePolicy(
      id: json['policy_id'],
      policyNumber: json['policy_number'],
      insurerName: json['insurer_name'],
      status: json['status'],
      premiumAmount: json['premium_amount']?.toDouble(),
      premiumDueDate: json['premium_due_date'],
      maturityDate: json['maturity_date'],
      sumAssured: json['sum_assured']?.toDouble(),
      customerName: json['customer_full_name'],
      customerPhone: json['customer_phone_number'],
    );
  }
}

class LifePoliciesState {
  final List<LifePolicy> policies;
  final bool isLoading;
  final bool hasMore;
  final String? error;
  final int page;
  
  LifePoliciesState({
    this.policies = const [],
    this.isLoading = true,
    this.hasMore = true,
    this.error,
    this.page = 1,
  });
  
  LifePoliciesState copyWith({
    List<LifePolicy>? policies,
    bool? isLoading,
    bool? hasMore,
    String? error,
    int? page,
  }) {
    return LifePoliciesState(
      policies: policies ?? this.policies,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      error: error ?? this.error,
      page: page ?? this.page,
    );
  }
}

class LifePoliciesNotifier extends Notifier<LifePoliciesState> {
  @override
  LifePoliciesState build() {
    return LifePoliciesState();
  }

  Future<void> fetchInitial(String filter) async {
    state = state.copyWith(isLoading: true, error: null, page: 1, hasMore: true);
    try {
      final res = await apiService.dio.get('/life-insurance/policies', queryParameters: {
        'filter': filter,
        'page': 1,
        'limit': 20,
      });
      final List data = res.data['items'];
      final policies = data.map((e) => LifePolicy.fromJson(e)).toList();
      state = state.copyWith(
        policies: policies,
        isLoading: false,
        hasMore: policies.length == 20,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> fetchMore(String filter) async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final nextPage = state.page + 1;
      final res = await apiService.dio.get('/life-insurance/policies', queryParameters: {
        'filter': filter,
        'page': nextPage,
        'limit': 20,
      });
      final List data = res.data['items'];
      final newPolicies = data.map((e) => LifePolicy.fromJson(e)).toList();
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

final lifePoliciesListProvider = NotifierProvider<LifePoliciesNotifier, LifePoliciesState>(
  LifePoliciesNotifier.new,
);
