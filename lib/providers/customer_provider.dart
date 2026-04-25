import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/customer_model.dart';
import '../services/api_service.dart';

class CustomerNotifier extends Notifier<AsyncValue<List<Customer>>> {
  @override
  AsyncValue<List<Customer>> build() {
    _fetchCustomers();
    return const AsyncValue.loading();
  }

  Future<void> _fetchCustomers() async {
    try {
      final response = await apiService.dio.get('/customers/');
      final List<dynamic> data = response.data;
      final customers = data.map((json) => Customer.fromJson(json)).toList();
      state = AsyncValue.data(customers);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addCustomer(Customer customer) async {
    try {
      final response = await apiService.dio.post('/customers/', data: customer.toJson());
      final newCustomer = Customer.fromJson(response.data);
      final current = state.asData?.value ?? [];
      state = AsyncValue.data([...current, newCustomer]);
    } catch (e) {
      debugPrint('Failed to add customer: $e');
      rethrow;
    }
  }

  void toggleActive(int id) {
    final current = state.asData?.value ?? [];
    state = AsyncValue.data(
      current.map((c) => c.id == id ? c.copyWith(isActive: !c.isActive) : c).toList(),
    );
  }
}

final customerProvider =
    NotifierProvider<CustomerNotifier, AsyncValue<List<Customer>>>(
        CustomerNotifier.new);
