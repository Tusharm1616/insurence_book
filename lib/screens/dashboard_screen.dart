import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/stats_tile.dart';
import '../widgets/shimmer_widget.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch dashboard stats when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dashboardStatsProvider.notifier).fetchDashboardStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dashboardStatsAsync = ref.watch(dashboardStatsProvider);
    
    return Scaffold(
      backgroundColor: AppThemeHelper.scaffoldBg(context),
      appBar: AppBar(
        title: const Text(
          'Statistics Overview',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'Poppins',
          ),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(dashboardStatsProvider.notifier).fetchDashboardStats();
        },
        child: dashboardStatsAsync.when(
          data: (stats) => _buildDashboardContent(context, theme, stats),
          loading: () => _buildLoadingState(),
          error: (err, _) => _buildErrorState(err.toString()),
        ),
      ),
    );
  }

  Widget _buildDashboardContent(
      BuildContext context, ThemeData theme, DashboardStats stats) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            'Statistics Overview',
            style: theme.textTheme.headlineLarge?.copyWith(
              color: AppColors.primary,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 24),
          
          // Stats Tiles Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.4,
            children: [
              // All Customers Tile
              StatsTile(
                icon: Icons.people_alt_outlined,
                iconColor: AppColors.info,
                title: 'All Customers',
                count: stats.allCustomers,
                countColor: AppColors.info,
                onTap: () {
                  Navigator.pushNamed(context, '/customer_list', arguments: {
                    'filter': 'all',
                    'title': 'All Customers',
                  });
                },
              ),
              
              // All Policies Tile
              StatsTile(
                icon: Icons.shield_outlined,
                iconColor: AppColors.primary,
                title: 'All Policies',
                count: stats.allPolicies,
                countColor: AppColors.primary,
                onTap: () {
                  Navigator.pushNamed(context, '/policy_list', arguments: {
                    'filter': 'all',
                    'title': 'All Policies',
                  });
                },
              ),
              
              // Expired Policy Tile
              StatsTile(
                icon: Icons.warning_amber_outlined,
                iconColor: AppColors.danger,
                title: 'Expired Policy',
                count: stats.expiredPolicies,
                countColor: AppColors.danger,
                onTap: () {
                  Navigator.pushNamed(context, '/policy_list', arguments: {
                    'filter': 'expired',
                    'title': 'Expired Policies',
                  });
                },
              ),
              
              // Expiring Within 1 Month Tile
              StatsTile(
                icon: Icons.calendar_month_outlined,
                iconColor: AppColors.warning,
                title: 'Expiring Within 1 Month',
                count: stats.expiring1Month,
                countColor: AppColors.warning,
                onTap: () {
                  Navigator.pushNamed(context, '/policy_list', arguments: {
                    'filter': 'expiring_1m',
                    'title': 'Expiring in 1 Month',
                  });
                },
              ),
              
              // Expiring Within 2 Months Tile
              StatsTile(
                icon: Icons.calendar_today_outlined,
                iconColor: AppColors.amber,
                title: 'Expiring Within 2 Months',
                count: stats.expiring2Months,
                countColor: AppColors.amber,
                onTap: () {
                  Navigator.pushNamed(context, '/policy_list', arguments: {
                    'filter': 'expiring_2m',
                    'title': 'Expiring in 2 Months',
                  });
                },
              ),
              
              // Active Customers Tile
              StatsTile(
                icon: Icons.person_pin_outlined,
                iconColor: AppColors.teal,
                title: 'Active Customers',
                count: stats.activeCustomers,
                countColor: AppColors.teal,
                onTap: () {
                  Navigator.pushNamed(context, '/customer_list', arguments: {
                    'filter': 'active',
                    'title': 'Active Customers',
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.4,
      children: List.generate(6, (index) => const ShimmerWidget()),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: AppColors.danger,
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading dashboard',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.danger,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 16),
          Text(
            error,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.danger,
              fontFamily: 'Poppins',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              ref.read(dashboardStatsProvider.notifier).fetchDashboardStats();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
