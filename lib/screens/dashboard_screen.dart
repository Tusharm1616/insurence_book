import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../core/theme.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/shimmer_widget.dart';
import 'global_search_delegate.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // build() auto-fetches on first load and after invalidation.
    // Only trigger a refresh here if data is already stale (not loading).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final current = ref.read(dashboardStatsProvider);
      if (current is! AsyncLoading) {
        ref.read(dashboardStatsProvider.notifier).fetchDashboardStats();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(dashboardStatsProvider);

    return Scaffold(
      backgroundColor: AppThemeHelper.scaffoldBg(context),
      appBar: _buildAppBar(context),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          await ref.read(dashboardStatsProvider.notifier).fetchDashboardStats();
        },
        child: dashboardAsync.when(
          data: (stats) => _buildBody(context, stats),
          loading: () => _buildLoading(),
          error: (err, _) => _buildError(err.toString()),
        ),
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      title: const Text(
        'Agent Dashboard',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20,
          color: Colors.white,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(LucideIcons.search, color: Colors.white),
          onPressed: () {
            showSearch(
              context: context,
              delegate: GlobalSearchDelegate(ref),
            );
          },
        ),
        IconButton(
          icon: const Icon(LucideIcons.bell, color: Colors.white),
          onPressed: () {
            Navigator.pushNamed(
              context,
              '/reminders',
              arguments: {'type': 'birthday'},
            );
          },
        ),
      ],
    );
  }

  // ── Main Body ─────────────────────────────────────────────────────────────
  Widget _buildBody(BuildContext context, DashboardStats stats) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Quick Actions ──────────────────────────────────────────────
          _buildQuickActions(context),

          const SizedBox(height: 4),

          // ── Statistics Overview ────────────────────────────────────────
          _buildSectionHeader(
            context,
            LucideIcons.barChart2,
            'Statistics Overview',
          ),
          const SizedBox(height: 8),
          _buildStatsList(context, stats),

          const SizedBox(height: 4),

          // ── Upcoming Items ─────────────────────────────────────────────
          _buildSectionHeader(
            context,
            LucideIcons.inbox,
            'Upcoming Items',
          ),
          const SizedBox(height: 8),
          _buildUpcomingItems(context),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ── Quick Actions Row ─────────────────────────────────────────────────────
  Widget _buildQuickActions(BuildContext context) {
    return Container(
      color: AppThemeHelper.cardColor(context),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      child: Row(
        children: [
          Expanded(
            child: _QuickActionButton(
              icon: LucideIcons.userPlus,
              label: 'Add Customer',
              onTap: () => Navigator.pushNamed(context, '/create_customer'),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _QuickActionButton(
              icon: LucideIcons.filePlus,
              label: 'Add Policy',
              onTap: () => Navigator.pushNamed(context, '/add_policy'),
            ),
          ),
        ],
      ),
    );
  }

  // ── Section Header ────────────────────────────────────────────────────────
  Widget _buildSectionHeader(
      BuildContext context, IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppThemeHelper.textPrimary(context),
            ),
          ),
        ],
      ),
    );
  }

  // ── Statistics List ───────────────────────────────────────────────────────
  Widget _buildStatsList(BuildContext context, DashboardStats stats) {
    final items = [
      _StatRow(
        icon: LucideIcons.users,
        iconColor: AppColors.info,
        label: 'All Customer',
        count: stats.allCustomers,
        countColor: AppColors.info,
        onTap: () => Navigator.pushNamed(
          context,
          '/customer_list',
          arguments: {'filter': 'all', 'title': 'All Customers'},
        ),
      ),
      _StatRow(
        icon: LucideIcons.shield,
        iconColor: AppColors.primary,
        label: 'All Policy',
        count: stats.allPolicies,
        countColor: AppColors.primary,
        onTap: () => Navigator.pushNamed(
          context,
          '/policy_list',
          arguments: {'filter': 'all', 'title': 'All Policies'},
        ),
      ),
      _StatRow(
        icon: LucideIcons.alertTriangle,
        iconColor: AppColors.danger,
        label: 'Expired Policy',
        count: stats.expiredPolicies,
        countColor: AppColors.danger,
        onTap: () => Navigator.pushNamed(context, '/expired_policies'),
      ),
      _StatRow(
        icon: LucideIcons.calendarDays,
        iconColor: AppColors.warning,
        label: 'Expiring Within 1 Month',
        count: stats.expiring1Month,
        countColor: AppColors.warning,
        onTap: () => Navigator.pushNamed(
          context,
          '/expiring_policies',
          arguments: {'days': 30, 'title': 'Expiring in 1 Month'},
        ),
      ),
      _StatRow(
        icon: LucideIcons.calendar,
        iconColor: AppColors.amber,
        label: 'Expiring Within 2 Months',
        count: stats.expiring2Months,
        countColor: AppColors.amber,
        onTap: () => Navigator.pushNamed(
          context,
          '/expiring_policies',
          arguments: {'days': 60, 'title': 'Expiring in 2 Months'},
        ),
      ),
      _StatRow(
        icon: LucideIcons.userCheck,
        iconColor: AppColors.teal,
        label: 'Active Customers',
        count: stats.activeCustomers,
        countColor: AppColors.teal,
        onTap: () => Navigator.pushNamed(
          context,
          '/customer_list',
          arguments: {'filter': 'active', 'title': 'Active Customers'},
        ),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: AppThemeHelper.cardColor(context),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppThemeHelper.shadowColor(context),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: List.generate(items.length, (i) {
            return Column(
              children: [
                _buildStatTile(context, items[i]),
                if (i < items.length - 1)
                  Divider(
                    height: 1,
                    indent: 60,
                    endIndent: 0,
                    color: AppThemeHelper.dividerColor(context),
                  ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildStatTile(BuildContext context, _StatRow item) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        child: Row(
          children: [
            // Circular icon
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: item.iconColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(item.icon, color: item.iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            // Label
            Expanded(
              child: Text(
                item.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppThemeHelper.textPrimary(context),
                ),
              ),
            ),
            // Count
            Text(
              '${item.count}',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: item.countColor,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              LucideIcons.chevronRight,
              size: 16,
              color: AppThemeHelper.textSecondary(context),
            ),
          ],
        ),
      ),
    );
  }

  // ── Upcoming Items ────────────────────────────────────────────────────────
  Widget _buildUpcomingItems(BuildContext context) {
    final items = [
      _UpcomingRow(
        icon: LucideIcons.cake,
        iconColor: Colors.pink,
        bgColor: Colors.pink.shade50,
        label: 'Birthdays',
        subtitle: 'Upcoming customer birthdays',
        onTap: () => Navigator.pushNamed(
          context,
          '/reminders',
          arguments: {'type': 'birthday'},
        ),
      ),
      _UpcomingRow(
        icon: LucideIcons.heart,
        iconColor: Colors.red,
        bgColor: Colors.red.shade50,
        label: 'Anniversaries',
        subtitle: 'Upcoming customer anniversaries',
        onTap: () => Navigator.pushNamed(
          context,
          '/reminders',
          arguments: {'type': 'anniversary'},
        ),
      ),
      _UpcomingRow(
        icon: LucideIcons.car,
        iconColor: Colors.orange,
        bgColor: Colors.orange.shade50,
        label: 'Motor Calculator',
        subtitle: 'Calculate motor insurance premium',
        onTap: () => Navigator.pushNamed(context, '/motor_calculator'),
      ),
      _UpcomingRow(
        icon: LucideIcons.fileText,
        iconColor: AppColors.indigo,
        bgColor: Colors.indigo.shade50,
        label: 'Vehicle Documents',
        subtitle: 'Track vehicle document expiry',
        onTap: () => Navigator.pushNamed(context, '/vehicle_document'),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: AppThemeHelper.cardColor(context),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppThemeHelper.shadowColor(context),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: List.generate(items.length, (i) {
            return Column(
              children: [
                _buildUpcomingTile(context, items[i]),
                if (i < items.length - 1)
                  Divider(
                    height: 1,
                    indent: 60,
                    endIndent: 0,
                    color: AppThemeHelper.dividerColor(context),
                  ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildUpcomingTile(BuildContext context, _UpcomingRow item) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: item.bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(item.icon, color: item.iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppThemeHelper.textPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppThemeHelper.textSecondary(context),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              LucideIcons.chevronRight,
              size: 16,
              color: AppThemeHelper.textSecondary(context),
            ),
          ],
        ),
      ),
    );
  }

  // ── Loading ───────────────────────────────────────────────────────────────
  Widget _buildLoading() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: AppThemeHelper.cardColor(context),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const ShimmerWidget(),
          ),
          const SizedBox(height: 16),
          ...List.generate(
            6,
            (_) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                height: 60,
                decoration: BoxDecoration(
                  color: AppThemeHelper.cardColor(context),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const ShimmerWidget(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Error ─────────────────────────────────────────────────────────────────
  Widget _buildError(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.wifiOff, size: 64, color: AppColors.danger),
            const SizedBox(height: 16),
            Text(
              'Failed to load dashboard',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppThemeHelper.textPrimary(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(
                fontSize: 13,
                color: AppThemeHelper.textSecondary(context),
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () =>
                  ref.read(dashboardStatsProvider.notifier).fetchDashboardStats(),
              icon: const Icon(LucideIcons.refreshCw, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(140, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Data classes (private)
// ─────────────────────────────────────────────────────────────────────────────

class _StatRow {
  final IconData icon;
  final Color iconColor;
  final String label;
  final int count;
  final Color countColor;
  final VoidCallback onTap;

  const _StatRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.count,
    required this.countColor,
    required this.onTap,
  });
}

class _UpcomingRow {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _UpcomingRow({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick Action Button widget
// ─────────────────────────────────────────────────────────────────────────────

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: AppThemeHelper.surfaceColor(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppThemeHelper.borderColor(context)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary, size: 26),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppThemeHelper.textPrimary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
