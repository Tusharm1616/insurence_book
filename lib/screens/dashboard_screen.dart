import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';

import '../core/app_theme.dart';
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
      backgroundColor: AppTheme.bgColor,
      appBar: AppBar(
        title: const Text(
          'Statistics Overview',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'Poppins',
          ),
        ),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(dashboardStatsProvider.notifier).fetchDashboardStats();
        },
        child: dashboardStatsAsync.when(
          data: (stats) => _buildDashboardContent(context, stats),
          loading: () => _buildLoadingState(),
          error: (error) => _buildErrorState(error),
        ),
      ),
    );
  }

  Widget _buildDashboardContent(BuildContext context, DashboardStats stats) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            'Statistics Overview',
            style: theme.textTheme.headlineLarge?.copyWith(
              color: AppTheme.primaryColor,
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
                iconColor: AppTheme.infoColor,
                title: 'All Customers',
                count: stats.all_customers,
                countColor: AppTheme.infoColor,
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
                iconColor: AppTheme.primaryColor,
                title: 'All Policies',
                count: stats.all_policies,
                countColor: AppTheme.primaryColor,
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
                iconColor: AppTheme.dangerColor,
                title: 'Expired Policy',
                count: stats.expired_policies,
                countColor: AppTheme.dangerColor,
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
                iconColor: AppTheme.warningColor,
                title: 'Expiring Within 1 Month',
                count: stats.expiring_1_month,
                countColor: AppTheme.warningColor,
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
                iconColor: AppTheme.amberColor,
                title: 'Expiring Within 2 Months',
                count: stats.expiring_2_months,
                countColor: AppTheme.amberColor,
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
                iconColor: AppTheme.tealColor,
                title: 'Active Customers',
                count: stats.active_customers,
                countColor: AppTheme.tealColor,
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
            color: AppTheme.dangerColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Error loading dashboard',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppTheme.dangerColor,
              fontFamily: 'Poppins',
            ),
          ),
          const SizedBox(height: 16),
          Text(
            error,
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.dangerColor,
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
              backgroundColor: AppTheme.primaryColor,
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
