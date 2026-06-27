import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

class PolicyData {
  final String id;
  final String policyNumber;
  final String policyType;
  final String insurerName;
  final String planName;
  final double sumInsured;
  final double premiumAmount;
  final String startDate;
  final String endDate;
  final String status;
  final CustomerInfo customer;
  final int daysRemaining;

  PolicyData({
    required this.id,
    required this.policyNumber,
    required this.policyType,
    required this.insurerName,
    required this.planName,
    required this.sumInsured,
    required this.premiumAmount,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.customer,
    required this.daysRemaining,
  });
}

class CustomerInfo {
  final String id;
  final String fullName;
  final String phone;

  CustomerInfo({
    required this.id,
    required this.fullName,
    required this.phone,
  });
}

class PolicyListResponse {
  final int total;
  final int page;
  final int pages;
  final List<PolicyData> data;

  PolicyListResponse({
    required this.total,
    required this.page,
    required this.pages,
    required this.data,
  });
}

class PoliciesNotifier extends Notifier<AsyncValue<PolicyListResponse>> {
  int _currentPage = 1;
  String _currentFilter = 'all';
  String _searchQuery = '';
  final List<PolicyData> _allPolicies = [];

  @override
  AsyncValue<PolicyListResponse> build() => const AsyncValue.loading();

  Future<void> fetchPolicies({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _allPolicies.clear();
    }

    state = const AsyncValue.loading();
    try {
      final queryParams = <String, dynamic>{
        'page': _currentPage,
        'limit': 20,
        'filter': _currentFilter,
        if (_searchQuery.isNotEmpty) 'search': _searchQuery,
      };

      final response = await apiService.dio.get('/api/policies/', queryParameters: queryParams);
      final policyListResponse = PolicyListResponse(
        total: response.data['total'] ?? 0,
        page: response.data['page'] ?? 1,
        pages: response.data['pages'] ?? 1,
        data: (response.data['data'] as List)
            .map((policy) => PolicyData(
                  id: policy['id'] ?? '',
                  policyNumber: policy['policy_number'] ?? '',
                  policyType: policy['policy_type'] ?? '',
                  insurerName: policy['insurer_name'] ?? '',
                  planName: policy['plan_name'] ?? '',
                  sumInsured: (policy['sum_assured'] ?? policy['sum_insured'] ?? 0.0).toDouble(),
                  premiumAmount: (policy['premium_amount'] ?? 0.0).toDouble(),
                  startDate: policy['start_date'] ?? '',
                  endDate: policy['end_date'] ?? '',
                  status: policy['status'] ?? '',
                  customer: CustomerInfo(
                    id: policy['customer']?['id'] ?? '',
                    fullName: policy['customer']?['full_name'] ?? 'Unknown',
                    phone: policy['customer']?['phone'] ?? '',
                  ),
                  daysRemaining: policy['days_remaining'] ?? 0,
                ))
            .toList(),
      );

      if (refresh) {
        _allPolicies.clear();
        _allPolicies.addAll(policyListResponse.data);
      } else {
        if (_currentPage == 1) {
          _allPolicies.clear();
          _allPolicies.addAll(policyListResponse.data);
        } else {
          _allPolicies.addAll(policyListResponse.data);
        }
      }

      state = AsyncValue.data(policyListResponse);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> loadMorePolicies() async {
    _currentPage++;
    await fetchPolicies();
  }

  void setFilter(String filter) {
    _currentFilter = filter;
    _currentPage = 1;
    _allPolicies.clear();
    fetchPolicies();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _currentPage = 1;
    _allPolicies.clear();
    fetchPolicies();
  }

  Future<void> refreshPolicies() async {
    await fetchPolicies(refresh: true);
  }

  Future<void> deletePolicy(String id) async {
    try {
      await apiService.dio.delete('/api/policies/$id');
      await fetchPolicies(refresh: true);
    } catch (e) {
      rethrow;
    }
  }
}

final policiesProvider =
    NotifierProvider<PoliciesNotifier, AsyncValue<PolicyListResponse>>(PoliciesNotifier.new);
