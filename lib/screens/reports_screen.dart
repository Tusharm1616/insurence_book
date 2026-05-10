import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/life_report_provider.dart';
import 'life_policy_list_screen.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(lifeReportProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(lifeReportProvider.future),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                Text(
                  'All Policies Report',
                  style: TextStyle(
                    fontSize: 24, 
                    fontWeight: FontWeight.bold, 
                    color: Theme.of(context).textTheme.displayLarge?.color
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap a tile to view detailed list',
                  style: TextStyle(
                    fontSize: 14, 
                    color: Theme.of(context).textTheme.bodyMedium?.color
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Policy Overview',
                  style: TextStyle(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold, 
                    color: Theme.of(context).textTheme.displayLarge?.color
                  ),
                ),
                const SizedBox(height: 16),
                reportAsync.when(
                  data: (data) => _buildGrid(context, data),
                  loading: () => const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator())),
                  error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGrid(BuildContext context, LifeReportSummary data) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.1,
      children: [
        _buildReportCard(
          context: context,
          icon: LucideIcons.checkCircle2,
          iconColor: const Color(0xFF4CAF50),
          value: data.live.toString(),
          label: 'Live Policy',
          filter: 'live',
        ),
        _buildReportCard(
          context: context,
          icon: LucideIcons.pauseCircle,
          iconColor: const Color(0xFFFF9800),
          value: data.premiumHoliday.toString(),
          label: 'Premium Holiday',
          filter: 'premium holiday',
        ),
        _buildReportCard(
          context: context,
          icon: LucideIcons.checkSquare,
          iconColor: const Color(0xFF2196F3),
          value: data.premiumPaidup.toString(),
          label: 'Premium Paidup',
          filter: 'paidup',
        ),
        _buildReportCard(
          context: context,
          icon: LucideIcons.clock,
          iconColor: const Color(0xFFFFC107),
          value: data.upcomingMaturity.toString(),
          label: 'Upcoming Maturity',
          filter: 'upcoming maturity',
        ),
        _buildReportCard(
          context: context,
          icon: LucideIcons.award,
          iconColor: const Color(0xFF9C27B0),
          value: data.matured.toString(),
          label: 'Matured Policy',
          filter: 'matured',
        ),
        _buildReportCard(
          context: context,
          icon: LucideIcons.alertTriangle,
          iconColor: const Color(0xFFF44336),
          value: data.lapsed.toString(),
          label: 'Lapsed Policy',
          filter: 'lapsed',
        ),
      ],
    );
  }

  Widget _buildReportCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
    required String filter,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LifePolicyListScreen(
              filter: filter,
              title: label == 'Live Policy' ? 'Live Policies' : label,
              themeColor: iconColor,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              spreadRadius: 1,
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: iconColor),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 13, color: Colors.blueGrey, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}
