import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../core/api_service.dart';

class PolicyData {
  final String id;
  final String policy_number;
  final String policy_type;
  final String insurer_name;
  final String plan_name;
  final double sum_insured;
  final double premium_amount;
  final String start_date;
  final String end_date;
  final String status;
  final CustomerInfo customer;
  final int days_remaining;

  PolicyData({
    required this.id,
    required this.policy_number,
    required this.policy_type,
    required this.insurer_name,
    required this.plan_name,
    required this.sum_insured,
    required this.premium_amount,
    required this.start_date,
    required this.end_date,
    required this.status,
    required this.customer,
    required this.days_remaining,
  });
}

class CustomerInfo {
  final String id;
  final String full_name;
  final String phone;

  CustomerInfo({
    required this.id,
    required this.full_name,
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

class PoliciesNotifier extends StateNotifier<AsyncValue<PolicyListResponse>> {
  PoliciesNotifier(this.ref) : super(const AsyncValue.loading());

  final Ref ref;
  int _currentPage = 1;
  String _currentFilter = 'all';
  String _searchQuery = '';
  final List<PolicyData> _allPolicies = [];

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
      
      final response = await ApiService().get('/api/policies', queryParameters: queryParams);
      final policyListResponse = PolicyListResponse(
        total: response.data['total'] ?? 0,
        page: response.data['page'] ?? 1,
        pages: response.data['pages'] ?? 1,
        data: (response.data['data'] as List)
            .map((policy) => PolicyData(
              id: policy['id'] ?? '',
              policy_number: policy['policy_number'] ?? '',
              policy_type: policy['policy_type'] ?? '',
              insurer_name: policy['insurer_name'] ?? '',
              plan_name: policy['plan_name'] ?? '',
              sum_insured: (policy['sum_insured'] ?? 0.0).toDouble(),
              premium_amount: (policy['premium_amount'] ?? 0.0).toDouble(),
              start_date: policy['start_date'] ?? '',
              end_date: policy['end_date'] ?? '',
              status: policy['status'] ?? '',
              customer: CustomerInfo(
                id: policy['customer']['id'] ?? '',
                full_name: policy['customer']['full_name'] ?? '',
                phone: policy['customer']['phone'] ?? '',
              ),
              days_remaining: policy['days_remaining'] ?? 0,
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
    } catch (e) {
      state = AsyncValue.error(e.toString());
    }
  }

  void loadMorePolicies() async {
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

  void refreshPolicies() async {
    await fetchPolicies(refresh: true);
  }
}

final policiesProvider = StateNotifierProvider<PoliciesNotifier, AsyncValue<PolicyListResponse>>(
  (ref) => PoliciesNotifier(ref),
);
