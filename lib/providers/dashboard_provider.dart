import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../core/api_service.dart';

class DashboardStats {
  final int all_customers;
  final int all_policies;
  final int expired_policies;
  final int expiring_1_month;
  final int expiring_2_months;
  final int active_customers;

  DashboardStats({
    required this.all_customers,
    required this.all_policies,
    required this.expired_policies,
    required this.expiring_1_month,
    required this.expiring_2_months,
    required this.active_customers,
  });
}

class DashboardNotifier extends StateNotifier<AsyncValue<DashboardStats>> {
  DashboardNotifier(this.ref) : super(const AsyncValue.loading());

  final Ref ref;

  Future<void> fetchDashboardStats() async {
    state = const AsyncValue.loading();
    try {
      final response = await ApiService().get('/api/dashboard/stats');
      final stats = DashboardStats(
        all_customers: response.data['all_customers'] ?? 0,
        all_policies: response.data['all_policies'] ?? 0,
        expired_policies: response.data['expired_policies'] ?? 0,
        expiring_1_month: response.data['expiring_1_month'] ?? 0,
        expiring_2_months: response.data['expiring_2_months'] ?? 0,
        active_customers: response.data['active_customers'] ?? 0,
      );
      state = AsyncValue.data(stats);
    } catch (e) {
      state = AsyncValue.error(e.toString());
    }
  }
}

final dashboardStatsProvider = StateNotifierProvider<DashboardNotifier, AsyncValue<DashboardStats>>(
  (ref) => DashboardNotifier(ref),
);
