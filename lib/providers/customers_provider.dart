import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

class CustomerData {
  final String id;
  final String fullName;
  final String phone;
  final String email;
  final String city;
  final String status;
  final int totalPolicies;
  final int activePolicies;
  final String latestPolicyEndDate;

  CustomerData({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.city,
    required this.status,
    required this.totalPolicies,
    required this.activePolicies,
    required this.latestPolicyEndDate,
  });
}

class CustomerListResponse {
  final int total;
  final int page;
  final int pages;
  final List<CustomerData> data;

  CustomerListResponse({
    required this.total,
    required this.page,
    required this.pages,
    required this.data,
  });
}

class CustomersNotifier extends Notifier<AsyncValue<CustomerListResponse>> {
  int _currentPage = 1;
  String _currentFilter = 'all';
  String _searchQuery = '';
  final List<CustomerData> _allCustomers = [];

  @override
  AsyncValue<CustomerListResponse> build() => const AsyncValue.loading();

  Future<void> fetchCustomers({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _allCustomers.clear();
    }

    // Only show loading spinner on first page / refresh, not on pagination
    if (_currentPage == 1) {
      state = const AsyncValue.loading();
    }

    try {
      final queryParams = <String, dynamic>{
        'page': _currentPage,
        'limit': 20,
        if (_currentFilter != 'all') 'status': _currentFilter,
        if (_searchQuery.isNotEmpty) 'search': _searchQuery,
      };

      final response = await apiService.dio.get('/api/customers/', queryParameters: queryParams);
      final customerListResponse = CustomerListResponse(
        total: response.data['total'] ?? 0,
        page: response.data['page'] ?? 1,
        pages: response.data['pages'] ?? 1,
        data: (response.data['data'] as List)
            .map((customer) => CustomerData(
                  id: customer['id']?.toString() ?? '',
                  fullName: customer['full_name'] ?? '',
                  phone: customer['phone'] ?? '',
                  email: customer['email'] ?? '',
                  city: customer['city'] ?? '',
                  status: customer['status'] ?? 'active',
                  totalPolicies: customer['total_policies'] ?? 0,
                  activePolicies: customer['active_policies'] ?? 0,
                  latestPolicyEndDate: customer['latest_policy_end_date'] ?? '',
                ))
            .toList(),
      );

      if (_currentPage == 1) {
        _allCustomers.clear();
        _allCustomers.addAll(customerListResponse.data);
      } else {
        _allCustomers.addAll(customerListResponse.data);
      }

      state = AsyncValue.data(customerListResponse);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> loadMoreCustomers() async {
    // Don't load more if already loading or on first page
    final current = state.asData?.value;
    if (current == null) return;
    if (_currentPage >= current.pages) return;
    _currentPage++;
    await fetchCustomers();
  }

  void setFilter(String filter) {
    _currentFilter = filter;
    _currentPage = 1;
    _allCustomers.clear();
    // Trigger fetch — don't await here, it's fire-and-forget from UI
    fetchCustomers(refresh: true);
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _currentPage = 1;
    _allCustomers.clear();
    fetchCustomers(refresh: true);
  }

  Future<void> refreshCustomers() async {
    await fetchCustomers(refresh: true);
  }

  Future<void> deleteCustomer(String id) async {
    try {
      await apiService.dio.delete('/api/customers/$id');
      // After deleting, refresh the list
      await fetchCustomers(refresh: true);
    } catch (e) {
      rethrow;
    }
  }
}

final customersProvider =
    NotifierProvider<CustomersNotifier, AsyncValue<CustomerListResponse>>(CustomersNotifier.new);
