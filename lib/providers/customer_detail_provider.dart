import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

class CustomerDetail {
  final String id;
  final String fullName;
  final String phone;
  final String email;
  final String dob;
  final String address;
  final String city;
  final String state;
  final String pincode;
  final String status;
  final String createdAt;
  final List<PolicyDetail> policies;

  CustomerDetail({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.dob,
    required this.address,
    required this.city,
    required this.state,
    required this.pincode,
    required this.status,
    required this.createdAt,
    required this.policies,
  });
}

class PolicyDetail {
  final String id;
  final String policyNumber;
  final String policyType;
  final String insurerName;
  final String planName;
  final double sumInsured;
  final double premiumAmount;
  final String paymentMode;
  final String startDate;
  final String endDate;
  final String status;
  final String nomineeName;
  final String nomineeRelation;

  PolicyDetail({
    required this.id,
    required this.policyNumber,
    required this.policyType,
    required this.insurerName,
    required this.planName,
    required this.sumInsured,
    required this.premiumAmount,
    required this.paymentMode,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.nomineeName,
    required this.nomineeRelation,
  });
}

Future<CustomerDetail> _loadCustomerDetail(String customerId) async {
  final response = await apiService.dio.get('/api/customers/$customerId');
  final policies = (response.data['policies'] as List)
      .map((policy) => PolicyDetail(
            id: policy['id'] ?? '',
            policyNumber: policy['policy_number'] ?? '',
            policyType: policy['policy_type'] ?? '',
            insurerName: policy['insurer_name'] ?? '',
            planName: policy['plan_name'] ?? '',
            sumInsured: (policy['sum_insured'] ?? 0.0).toDouble(),
            premiumAmount: (policy['premium_amount'] ?? 0.0).toDouble(),
            paymentMode: policy['payment_mode'] ?? '',
            startDate: policy['start_date'] ?? '',
            endDate: policy['end_date'] ?? '',
            status: policy['status'] ?? '',
            nomineeName: policy['nominee_name'] ?? '',
            nomineeRelation: policy['nominee_relation'] ?? '',
          ))
      .toList();

  return CustomerDetail(
    id: response.data['id'] ?? '',
    fullName: response.data['full_name'] ?? '',
    phone: response.data['phone'] ?? '',
    email: response.data['email'] ?? '',
    dob: response.data['dob'] ?? '',
    address: response.data['address'] ?? '',
    city: response.data['city'] ?? '',
    state: response.data['state'] ?? '',
    pincode: response.data['pincode'] ?? '',
    status: response.data['status'] ?? '',
    createdAt: response.data['created_at'] ?? '',
    policies: policies,
  );
}

final customerDetailProvider =
    FutureProvider.family<CustomerDetail, String>((ref, customerId) async {
  return _loadCustomerDetail(customerId);
});
