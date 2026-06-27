import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../utils/lucide_compat.dart';
import '../core/theme.dart';
import '../providers/lead_provider.dart';

class LeadListScreen extends ConsumerWidget {
  final String title;
  final dynamic filterProvider;

  const LeadListScreen({
    super.key,
    required this.title,
    required this.filterProvider,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Support both sync providers and the async leadProvider
    List<Lead> leads;
    if (filterProvider == leadProvider) {
      leads = ref.watch(leadsListProvider);
    } else {
      leads = ref.watch(filterProvider as dynamic) as List<Lead>;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
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
                  Text(
                    'No Leads Found',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
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
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(lead.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                        // Show green "Converted" badge for converted leads
                        if (lead.status == LeadStatus.converted)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green.withValues(alpha: 0.4)),
                            ),
                            child: const Text(
                              'Converted',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green),
                            ),
                          ),
                      ],
                    ),
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
                        if (lead.followupDate != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(LucideIcons.calendar, size: 12, color: Colors.purple),
                              const SizedBox(width: 4),
                              Text(
                                'Follow-up: ${DateFormat('dd MMM yyyy, hh:mm a').format(lead.followupDate!)}',
                                style: const TextStyle(fontSize: 11, color: Colors.purple),
                              ),
                            ],
                          ),
                        ],
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
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Delete Lead'),
                                content: const Text('Are you sure you want to delete this lead?'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              try {
                                await ref.read(leadProvider.notifier).deleteLead(lead.id);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Lead deleted successfully')),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Failed to delete lead: $e')),
                                  );
                                }
                              }
                            }
                          },
                        ),
                        Icon(LucideIcons.chevronRight, size: 18, color: Theme.of(context).dividerColor),
                      ],
                    ),
                    onTap: () {
                      Navigator.pushNamed(context, '/lead_detail', arguments: {'lead': lead});
                    },
                  ),
                );
              },
            ),
    );
  }

  Color _getStatusColor(LeadStatus status) {
    switch (status) {
      case LeadStatus.newLead:
        return Colors.green;
      case LeadStatus.contacted:
        return Colors.teal;
      case LeadStatus.followupScheduled:
        return Colors.purple;
      case LeadStatus.proposalSent:
        return Colors.indigo;
      case LeadStatus.negotiation:
        return Colors.amber.shade800;
      case LeadStatus.converted:
        return Colors.blue;
      case LeadStatus.lost:
        return Colors.red;
      case LeadStatus.unassigned:
        return Colors.orange;
    }
  }
}
