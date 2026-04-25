import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/policy_model.dart';
import '../services/api_service.dart';

class PolicyNotifier extends Notifier<List<Policy>> {
  @override
  List<Policy> build() {
    _fetchPolicies();
    return [];
  }

  Future<void> _fetchPolicies() async {
    try {
      final response = await apiService.dio.get('/policies/');
      final data = response.data as List;
      state = data.map((json) => Policy.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error fetching policies: $e');
    }
  }

  Future<void> addPolicy(Policy policy) async {
    try {
      final response = await apiService.dio.post('/policies/', data: policy.toJson());
      final newPolicy = Policy.fromJson(response.data);
      state = [...state, newPolicy];
    } catch (e) {
      debugPrint('Error adding policy: $e');
      rethrow;
    }
  }

  void removePolicy(int id) {
    // Implement delete API if needed later
    state = state.where((p) => p.id != id).toList();
  }

  List<Policy> forCustomer(int customerId) {
    return state.where((p) => p.customerId == customerId).toList();
  }
}

final policyProvider =
    NotifierProvider<PolicyNotifier, List<Policy>>(PolicyNotifier.new);

/// Policies that are already past their expiry date
final expiredPoliciesProvider = Provider<List<Policy>>((ref) {
  return ref.watch(policyProvider).where((p) => p.isExpired).toList();
});

/// Active (non-expired) policies
final activePoliciesProvider = Provider<List<Policy>>((ref) {
  return ref.watch(policyProvider).where((p) => !p.isExpired).toList();
});

/// Life insurance policies only
final lifeInsurancePoliciesProvider = Provider<List<Policy>>((ref) {
  return ref.watch(policyProvider).where((p) => p.isLifeInsurance).toList();
});
