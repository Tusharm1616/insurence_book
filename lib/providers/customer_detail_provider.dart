import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../core/api_service.dart';

class CustomerDetail {
  final String id;
  final String full_name;
  final String phone;
  final String email;
  final String dob;
  final String address;
  final String city;
  final String state;
  final String pincode;
  final String status;
  final String created_at;
  final List<PolicyDetail> policies;

  CustomerDetail({
    required this.id,
    required this.full_name,
    required this.phone,
    required this.email,
    required this.dob,
    required this.address,
    required this.city,
    required this.state,
    required this.pincode,
    required this.status,
    required this.created_at,
    required this.policies,
  });
}

class PolicyDetail {
  final String id;
  final String policy_number;
  final String policy_type;
  final String insurer_name;
  final String plan_name;
  final double sum_insured;
  final double premium_amount;
  final String payment_mode;
  final String start_date;
  final String end_date;
  final String status;
  final String nominee_name;
  final String nominee_relation;

  PolicyDetail({
    required this.id,
    required this.policy_number,
    required this.policy_type,
    required this.insurer_name,
    required this.plan_name,
    required this.sum_insured,
    required this.premium_amount,
    required this.payment_mode,
    required this.start_date,
    required this.end_date,
    required this.status,
    required this.nominee_name,
    required this.nominee_relation,
  });
}

class CustomerDetailNotifier extends StateNotifier<AsyncValue<CustomerDetail>> {
  CustomerDetailNotifier(this.ref) : super(const AsyncValue.loading());

  final Ref ref;

  Future<void> fetchCustomerDetail(String customerId) async {
    state = const AsyncValue.loading();
    try {
      final response = await ApiService().get('/api/customers/$customerId');
      final policies = (response.data['policies'] as List)
          .map((policy) => PolicyDetail(
                id: policy['id'] ?? '',
                policy_number: policy['policy_number'] ?? '',
                policy_type: policy['policy_type'] ?? '',
                insurer_name: policy['insurer_name'] ?? '',
                plan_name: policy['plan_name'] ?? '',
                sum_insured: (policy['sum_insured'] ?? 0.0).toDouble(),
                premium_amount: (policy['premium_amount'] ?? 0.0).toDouble(),
                payment_mode: policy['payment_mode'] ?? '',
                start_date: policy['start_date'] ?? '',
                end_date: policy['end_date'] ?? '',
                status: policy['status'] ?? '',
                nominee_name: policy['nominee_name'] ?? '',
                nominee_relation: policy['nominee_relation'] ?? '',
              ))
          .toList();
      
      final customerDetail = CustomerDetail(
        id: response.data['id'] ?? '',
        full_name: response.data['full_name'] ?? '',
        phone: response.data['phone'] ?? '',
        email: response.data['email'] ?? '',
        dob: response.data['dob'] ?? '',
        address: response.data['address'] ?? '',
        city: response.data['city'] ?? '',
        state: response.data['state'] ?? '',
        pincode: response.data['pincode'] ?? '',
        status: response.data['status'] ?? '',
        created_at: response.data['created_at'] ?? '',
        policies: policies,
      );
      
      state = AsyncValue.data(customerDetail);
    } catch (e) {
      state = AsyncValue.error(e.toString());
    }
  }
}

final customerDetailProvider = StateNotifierProvider.family<CustomerDetailNotifier, AsyncValue<CustomerDetail>>(
  (ref, customerId) => CustomerDetailNotifier(ref),
);
