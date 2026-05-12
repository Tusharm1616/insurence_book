import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../core/api_service.dart';

class CustomerData {
  final String id;
  final String full_name;
  final String phone;
  final String email;
  final String city;
  final String status;
  final int total_policies;
  final int active_policies;
  final String latest_policy_end_date;

  CustomerData({
    required this.id,
    required this.full_name,
    required this.phone,
    required this.email,
    required this.city,
    required this.status,
    required this.total_policies,
    required this.active_policies,
    required this.latest_policy_end_date,
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

class CustomersNotifier extends StateNotifier<AsyncValue<CustomerListResponse>> {
  CustomersNotifier(this.ref) : super(const AsyncValue.loading());

  final Ref ref;
  int _currentPage = 1;
  String _currentFilter = 'all';
  String _searchQuery = '';
  final List<CustomerData> _allCustomers = [];

  Future<void> fetchCustomers({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _allCustomers.clear();
    }
    
    state = const AsyncValue.loading();
    try {
      final queryParams = <String, dynamic>{
        'page': _currentPage,
        'limit': 20,
        'status': _currentFilter,
        if (_searchQuery.isNotEmpty) 'search': _searchQuery,
      };
      
      final response = await ApiService().get('/api/customers', queryParameters: queryParams);
      final customerListResponse = CustomerListResponse(
        total: response.data['total'] ?? 0,
        page: response.data['page'] ?? 1,
        pages: response.data['pages'] ?? 1,
        data: (response.data['data'] as List)
            .map((customer) => CustomerData(
              id: customer['id'] ?? '',
              full_name: customer['full_name'] ?? '',
              phone: customer['phone'] ?? '',
              email: customer['email'] ?? '',
              city: customer['city'] ?? '',
              status: customer['status'] ?? 'active',
              total_policies: customer['total_policies'] ?? 0,
              active_policies: customer['active_policies'] ?? 0,
              latest_policy_end_date: customer['latest_policy_end_date'] ?? '',
            ))
            .toList(),
      );
      
      if (refresh) {
        _allCustomers.clear();
        _allCustomers.addAll(customerListResponse.data);
      } else {
        if (_currentPage == 1) {
          _allCustomers.clear();
          _allCustomers.addAll(customerListResponse.data);
        } else {
          _allCustomers.addAll(customerListResponse.data);
        }
      }
      
      state = AsyncValue.data(customerListResponse);
    } catch (e) {
      state = AsyncValue.error(e.toString());
    }
  }

  void loadMoreCustomers() async {
    _currentPage++;
    await fetchCustomers();
  }

  void setFilter(String filter) {
    _currentFilter = filter;
    _currentPage = 1;
    _allCustomers.clear();
    fetchCustomers();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    _currentPage = 1;
    _allCustomers.clear();
    fetchCustomers();
  }

  void refreshCustomers() async {
    await fetchCustomers(refresh: true);
  }
}

final customersProvider = StateNotifierProvider<CustomersNotifier, AsyncValue<CustomerListResponse>>(
  (ref) => CustomersNotifier(ref),
);
