import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

// ── Data models ───────────────────────────────────────────────────────────────

class CustomerDetail {
  final String id;
  final String fullName;
  final String phone;
  final String email;
  final String dob;
  final String anniversaryDate;
  final String address;
  final String city;
  final String state;
  final String pincode;
  final String refBy;
  final String status;
  final String createdAt;
  final List<PolicyDetail> policies;

  CustomerDetail({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.email,
    required this.dob,
    required this.anniversaryDate,
    required this.address,
    required this.city,
    required this.state,
    required this.pincode,
    required this.refBy,
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
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.nomineeName,
    required this.nomineeRelation,
  });

  factory PolicyDetail.fromJson(Map<String, dynamic> json) {
    // Handle both field name variants from different endpoints
    final startRaw = json['start_date'] ?? json['issue_date'] ?? '';
    final endRaw   = json['end_date']   ?? json['expiry_date'] ?? '';
    final sumRaw   = json['sum_insured'] ?? json['sum_assured'] ?? 0.0;

    return PolicyDetail(
      id:               json['id']?.toString() ?? '',
      policyNumber:     json['policy_number']  ?? '',
      policyType:       json['policy_type']    ?? '',
      insurerName:      json['insurer_name']   ?? '',
      planName:         json['plan_name']      ?? '',
      sumInsured:       (sumRaw as num).toDouble(),
      premiumAmount:    (json['premium_amount'] as num? ?? 0).toDouble(),
      startDate:        startRaw.toString(),
      endDate:          endRaw.toString(),
      status:           json['status']          ?? '',
      nomineeName:      json['nominee_name']    ?? '',
      nomineeRelation:  json['nominee_relation'] ?? '',
    );
  }
}

// ── Loader ────────────────────────────────────────────────────────────────────

Future<CustomerDetail> _loadCustomerDetail(String customerId) async {
  final response = await apiService.dio.get('/api/customers/$customerId');
  final data = response.data as Map<String, dynamic>;

  // policies may be null if the customer has no policies yet
  final rawPolicies = data['policies'];
  final List<PolicyDetail> policies = (rawPolicies is List)
      ? rawPolicies
          .map((p) => PolicyDetail.fromJson(p as Map<String, dynamic>))
          .toList()
      : [];

  return CustomerDetail(
    id:               data['id']?.toString()    ?? '',
    fullName:         data['full_name']          ?? '',
    phone:            data['phone']              ?? '',
    email:            data['email']              ?? '',
    dob:              data['dob']                ?? '',
    anniversaryDate:  data['anniversary_date']   ?? '',
    address:          data['address']            ?? '',
    city:             data['city']               ?? '',
    state:            data['state']              ?? '',
    pincode:          data['pincode']            ?? '',
    refBy:            data['ref_by']             ?? '',
    status:           data['status']             ?? '',
    createdAt:        data['created_at']         ?? '',
    policies:         policies,
  );
}

// ── Provider ──────────────────────────────────────────────────────────────────

final customerDetailProvider =
    FutureProvider.family<CustomerDetail, String>((ref, customerId) async {
  return _loadCustomerDetail(customerId);
});
