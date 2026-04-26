import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/theme.dart';
import '../providers/customer_provider.dart';
import '../providers/policy_provider.dart';
import '../providers/dashboard_provider.dart';
import '../providers/life_report_provider.dart';
import '../screens/customer_policy_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Live counts from providers
    final customers    = ref.watch(customerProvider).asData?.value ?? [];
    final policies     = ref.watch(policyProvider);
    final expired      = ref.watch(expiredPoliciesProvider);
    final lifePolicies = ref.watch(lifeInsurancePoliciesProvider);

    final totalCustomers  = customers.length;
    final activeCustomers = customers.where((c) => c.isActive).length;
    final totalPolicies   = policies.length;
    final expiredCount    = expired.length;

    // Life Insurance Report breakdown
    final expiringSoon      = lifePolicies.where((p) => p.isExpiringSoon).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agent Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeCard(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // ── Quick Actions ────────────────────────────────
                  _buildSectionHeader('Quick Actions', LucideIcons.zap),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/create_customer'),
                        child: _buildActionCard('Add Customer', LucideIcons.userPlus, Colors.green),
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/add_policy'),
                        child: _buildActionCard('Add Policy', LucideIcons.fileText, Colors.blueGrey),
                      )),
                    ],
                  ),

                  // ── Statistics Overview ──────────────────────────
                  const SizedBox(height: 24),
                  _buildSectionHeader('Statistics Overview', LucideIcons.barChart),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/customers'),
                    child: _buildStatRowCard('All Customer', '$totalCustomers', LucideIcons.users, Colors.blue),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerPolicyScreen())),
                    child: _buildStatRowCard('All Policy', '$totalPolicies', LucideIcons.shield, Colors.green),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(
                      builder: (_) => const CustomerPolicyScreen(customerName: 'Expired Policies — All'),
                    )),
                    child: _buildStatRowCard('Expired Policy', '$expiredCount', LucideIcons.alertTriangle, Colors.red),
                  ),
                  const SizedBox(height: 8),
                  
                  // New Expiring Policy Tiles
                  Consumer(
                    builder: (context, ref, child) {
                      final countsAsync = ref.watch(expiringCountsProvider);
                      final count1m = countsAsync.when(
                        data: (d) => '${d.month1}',
                        loading: () => '--',
                        error: (e, st) => '--',
                      );
                      final count2m = countsAsync.when(
                        data: (d) => '${d.month2}',
                        loading: () => '--',
                        error: (e, st) => '--',
                      );
                      
                      return Column(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.pushNamed(context, '/expiring_policies', arguments: {'days': 30, 'title': 'Expiring Within 1 Month'}),
                            child: _buildStatRowCard('Expiring Within 1 Month', count1m, LucideIcons.calendar, const Color(0xFFFF9800)),
                          ),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () => Navigator.pushNamed(context, '/expiring_policies', arguments: {'days': 60, 'title': 'Expiring Within 2 Months'}),
                            child: _buildStatRowCard('Expiring Within 2 Months', count2m, LucideIcons.calendarDays, const Color(0xFFFFC107)),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 8),

                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/customers'),
                    child: _buildStatRowCard('Active Customers', '$activeCustomers', LucideIcons.userCheck, Colors.teal),
                  ),

                  // ── Upcoming Items ───────────────────────────────
                  const SizedBox(height: 24),
                  _buildSectionHeader('Upcoming Items', LucideIcons.inbox),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerPolicyScreen(customerName: 'Upcoming Renewals'))),
                        child: _buildInfoCard('Upcoming Renewal & Due Premium', 'Policies expiring in 30 days: $expiringSoon', LucideIcons.calendar, Colors.green),
                      )),
                      const SizedBox(width: 12),
                      Expanded(child: GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomerPolicyScreen(customerName: 'Expired Policies'))),
                        child: _buildInfoCard('Overdue Premium', '$expiredCount policies with overdue payments', LucideIcons.alertCircle, Colors.red),
                      )),
                    ],
                  ),

                  // ── Life Insurance Report ────────────────────────
                  const SizedBox(height: 24),
                  _buildSectionHeader('Life Insurance Report', LucideIcons.clipboardList),
                  const SizedBox(height: 12),
                  Consumer(
                    builder: (context, ref, child) {
                      final reportAsync = ref.watch(lifeReportProvider);
                      return reportAsync.when(
                        data: (report) => _buildGridReport(context, report),
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, st) => const Center(child: Text('Failed to load report')),
                      );
                    },
                  ),

                  // ── Other Features ───────────────────────────────
                  const SizedBox(height: 24),
                  _buildSectionHeader('Other Features', LucideIcons.moreHorizontal),
                  const SizedBox(height: 12),
                  _buildFeatureRow(context, 'Vehicle Document Validity', 'RTO Document Status & Expiry', LucideIcons.car, Colors.teal),
                  _buildFeatureRow(context, 'Customers Birthday', 'Customers birthday reminders', LucideIcons.cake, Colors.pink, route: '/reminders', routeArgs: {'type': 'birthdays'}),
                  _buildFeatureRow(context, 'Customers Anniversary', 'Customers anniversary reminders', LucideIcons.heart, Colors.red, route: '/reminders', routeArgs: {'type': 'anniversaries'}),
                  _buildFeatureRow(context, 'Motor Insurance Calculator', 'Calculate premium & generate PDF quotes', LucideIcons.calculator, Colors.purple, route: '/motor_calculator'),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.secondary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.secondary.withValues(alpha: 0.2)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          child: const Icon(LucideIcons.user, color: AppColors.primary, size: 30),
        ),
        const SizedBox(width: 16),
        const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Welcome back,', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          Text('John Doe', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
        ]),
      ]),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
        child: Icon(icon, size: 16, color: AppColors.primary),
      ),
      const SizedBox(width: 8),
      Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
    ]);
  }

  Widget _buildActionCard(String title, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ]),
      ),
    );
  }

  Widget _buildStatRowCard(String title, String count, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 16),
          Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600))),
          Text(count, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(width: 8),
          const Icon(LucideIcons.chevronRight, size: 16, color: Colors.grey),
        ]),
      ),
    );
  }

  Widget _buildInfoCard(String title, String sub, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 2),
          const SizedBox(height: 4),
          Text(sub, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ]),
      ),
    );
  }

  Widget _buildGridReport(BuildContext context, LifeReportSummary report) {
    final reports = [
      {'title': 'Live Policy',       'icon': LucideIcons.checkCircle,  'color': Colors.green,      'count': report.live, 'filter': 'live'},
      {'title': 'Premium Holiday',   'icon': LucideIcons.pauseCircle,  'color': Colors.orange,     'count': report.premiumHoliday, 'filter': 'premium holiday'},
      {'title': 'Premium Paidup',    'icon': LucideIcons.checkCircle2, 'color': Colors.purple,     'count': report.premiumPaidup, 'filter': 'paidup'},
      {'title': 'Upcoming Maturity', 'icon': LucideIcons.clock,        'color': Colors.teal,       'count': report.upcomingMaturity, 'filter': 'upcoming maturity'},
      {'title': 'Matured Policy',    'icon': LucideIcons.calendarCheck,'color': Colors.deepPurple, 'count': report.matured, 'filter': 'matured'},
      {'title': 'Lapsed Policy',     'icon': LucideIcons.xCircle,      'color': Colors.red,        'count': report.lapsed, 'filter': 'lapsed'},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, childAspectRatio: 1.4, crossAxisSpacing: 10, mainAxisSpacing: 10,
      ),
      itemCount: reports.length,
      itemBuilder: (context, index) {
        final r = reports[index];
        return GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/life_policies', arguments: {
            'filter': r['filter'],
            'title': r['title'],
            'color': r['color'],
          }),
          child: Card(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(r['icon'] as IconData, color: r['color'] as Color, size: 24),
              const SizedBox(height: 6),
              Text('${r['count']}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: r['color'] as Color)),
              Text(r['title'] as String, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
            ]),
          ),
        );
      },
    );
  }

  Widget _buildFeatureRow(BuildContext context, String title, String sub, IconData icon, Color color, {String? route, Map<String, dynamic>? routeArgs}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
      child: ListTile(
        onTap: () { if (route != null) Navigator.pushNamed(context, route, arguments: routeArgs); },
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(sub, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        trailing: const Icon(LucideIcons.chevronRight, size: 18, color: Colors.grey),
      ),
    );
  }
}
