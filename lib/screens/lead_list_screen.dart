import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../core/theme.dart';
import '../providers/lead_provider.dart';

class LeadListScreen extends ConsumerWidget {
  final String title;
  final dynamic filterProvider;

  const LeadListScreen({super.key, required this.title, required this.filterProvider});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leads = ref.watch(filterProvider as dynamic); // Dynamic cast to handle StateNotifierProvider / Provider

    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: leads.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.inbox, size: 48, color: Theme.of(context).dividerColor),
                  const SizedBox(height: 16),
                  Text('No Leads Found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyMedium?.color)),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: leads.length,
              itemBuilder: (context, index) {
                final Lead lead = leads[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 1,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: _getStatusColor(lead.status).withValues(alpha: 0.1),
                      child: Icon(LucideIcons.user, color: _getStatusColor(lead.status)),
                    ),
                    title: Text(lead.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(LucideIcons.phone, size: 12, color: AppColors.navInactive),
                            const SizedBox(width: 4),
                            Text(lead.mobile, style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getStatusColor(lead.status).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            lead.status.label,
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: _getStatusColor(lead.status)),
                          ),
                        ),
                      ],
                    ),
                    trailing: Icon(LucideIcons.chevronRight, size: 18, color: Theme.of(context).dividerColor),
                    onTap: () {
                      // Optionally open a lead details bottom sheet here
                    },
                  ),
                );
              },
            ),
    );
  }

  Color _getStatusColor(LeadStatus status) {
    switch (status) {
      case LeadStatus.newLead: return Colors.green;
      case LeadStatus.followup: return Colors.purple;
      case LeadStatus.converted: return Colors.blue;
      case LeadStatus.lost: return Colors.red;
      case LeadStatus.unassigned: return Colors.orange;
    }
  }
}
