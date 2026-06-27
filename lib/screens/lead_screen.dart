import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/lucide_compat.dart';
import '../core/theme.dart';
import '../providers/lead_provider.dart';

class LeadScreen extends ConsumerWidget {
  const LeadScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leadsAsync = ref.watch(leadProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lead', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: AppThemeHelper.scaffoldBg(context),
      body: leadsAsync.when(
        data: (allLeads) => _buildBody(context, ref, allLeads),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading leads: $e')),
      ),
    );
  }

  Widget _buildBody(BuildContext context, WidgetRef ref, List<Lead> allLeads) {
    final newLeads = allLeads.where((l) => l.status == LeadStatus.newLead).toList();
    final unassigned = allLeads.where((l) => l.status == LeadStatus.unassigned).toList();
    final today = DateTime.now();
    final todayFollowups = allLeads.where((l) {
      if (l.followupDate == null) return false;
      final f = l.followupDate!;
      return f.year == today.year && f.month == today.month && f.day == today.day;
    }).toList();
    final converted = allLeads.where((l) => l.status == LeadStatus.converted).toList();
    final lost = allLeads.where((l) => l.status == LeadStatus.lost).toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Blue Lead Overview Banner
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(LucideIcons.barChart2, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Lead Overview', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    Text('Total ${allLeads.length} leads', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),

          // Metrics Grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.8,
              children: [
                _metricCard(context, LucideIcons.users, Colors.blueGrey, 'Total Leads', allLeads.length, null),
                _metricCard(context, LucideIcons.zap, Colors.green, 'New Leads', newLeads.length, 'NEW'),
                _metricCard(context, LucideIcons.userMinus, Colors.orange, 'Unassigned', unassigned.length, null),
                _metricCard(context, LucideIcons.calendar, Colors.purple, 'Today\'s Follow-ups', todayFollowups.length, null),
                _metricCard(context, LucideIcons.checkCircle, Colors.lightBlue, 'Converted', converted.length, null),
                _metricCard(context, LucideIcons.xCircle, Colors.red, 'Lost Leads', lost.length, null),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Lead Actions Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(LucideIcons.zap, size: 20, color: AppColors.primary),
                const SizedBox(width: 8),
                Text('Lead Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppThemeHelper.textPrimary(context))),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Action List
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _actionTile(context, LucideIcons.userPlus, 'Add Lead', () => Navigator.pushNamed(context, '/add_lead')),
                _actionTile(context, LucideIcons.list, 'View All Lead', () => Navigator.pushNamed(context, '/all_leads')),
                _actionTile(context, LucideIcons.userMinus, 'Unassign Lead', () => Navigator.pushNamed(context, '/unassigned_leads')),
                _actionTile(context, LucideIcons.calendarClock, 'Followup Lead', () => Navigator.pushNamed(context, '/followup_leads')),
                _actionTile(context, LucideIcons.alertTriangle, 'Over Due Followup Lead', () => Navigator.pushNamed(context, '/overdue_leads')),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _metricCard(BuildContext context, IconData icon, Color color, String title, int count, String? badge) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppThemeHelper.cardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppThemeHelper.borderColor(context)),
        boxShadow: AppThemeHelper.isDark(context) ? [] : [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (badge != null)
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                  child: Text(badge, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.bold)),
                )
              else
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: Icon(icon, color: color, size: 16),
                ),
              Text('$count', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          const SizedBox(height: 6),
          Text(title, style: TextStyle(fontSize: 12, color: AppThemeHelper.textSecondary(context), fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _actionTile(BuildContext context, IconData icon, String title, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppThemeHelper.cardColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppThemeHelper.borderColor(context)),
        boxShadow: AppThemeHelper.isDark(context) ? [] : [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        trailing: const Icon(LucideIcons.chevronRight, size: 18, color: Colors.grey),
      ),
    );
  }
}
