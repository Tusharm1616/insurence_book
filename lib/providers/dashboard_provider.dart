import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

class DashboardStats {
  final int allCustomers;
  final int allPolicies;
  final int expiredPolicies;
  final int expiring1Month;
  final int expiring2Months;
  final int activeCustomers;

  DashboardStats({
    required this.allCustomers,
    required this.allPolicies,
    required this.expiredPolicies,
    required this.expiring1Month,
    required this.expiring2Months,
    required this.activeCustomers,
  });
}

class DashboardNotifier extends Notifier<AsyncValue<DashboardStats>> {
  @override
  AsyncValue<DashboardStats> build() => const AsyncValue.loading();

  Future<void> fetchDashboardStats() async {
    state = const AsyncValue.loading();
    try {
      final response = await apiService.dio.get('/api/dashboard/stats');
      final stats = DashboardStats(
        allCustomers: response.data['all_customers'] ?? 0,
        allPolicies: response.data['all_policies'] ?? 0,
        expiredPolicies: response.data['expired_policies'] ?? 0,
        expiring1Month: response.data['expiring_1_month'] ?? 0,
        expiring2Months: response.data['expiring_2_months'] ?? 0,
        activeCustomers: response.data['active_customers'] ?? 0,
      );
      state = AsyncValue.data(stats);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final dashboardStatsProvider =
    NotifierProvider<DashboardNotifier, AsyncValue<DashboardStats>>(DashboardNotifier.new);
