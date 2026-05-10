import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../providers/life_policy_list_provider.dart';

class LifePolicyDetailScreen extends StatelessWidget {
  final LifePolicy policy;

  const LifePolicyDetailScreen({super.key, required this.policy});

  @override
  Widget build(BuildContext context) {
    int daysUntilExpiry = 0;
    bool isExpiringSoon = false;

    if (policy.premiumDueDate != null) {
      try {
        final dueDate = DateTime.parse(policy.premiumDueDate!);
        daysUntilExpiry = dueDate.difference(DateTime.now()).inDays;
        isExpiringSoon = daysUntilExpiry <= 30 && daysUntilExpiry >= 0;
      } catch (_) {}
    }

    String sumAssuredStr = policy.sumAssured != null ? '₹${(policy.sumAssured! / 100000).toStringAsFixed(0)}L' : 'N/A';
    String premiumStr = policy.premiumAmount != null ? '₹${policy.premiumAmount!.toStringAsFixed(0)}' : 'N/A';

    return Scaffold(
      appBar: AppBar(
        title: Text(policy.policyNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: false,
      ),
      backgroundColor: Colors.grey.shade50,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Green Hero Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text(premiumStr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(height: 4),
                        const Text('Premium', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 40, color: Colors.white30),
                  Expanded(
                    child: Column(
                      children: [
                        Text(sumAssuredStr, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                        const SizedBox(height: 4),
                        const Text('Sum Assured', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                  Container(width: 1, height: 40, color: Colors.white30),
                  Expanded(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(4)),
                          child: Text(policy.status, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                        const SizedBox(height: 4),
                        const Text('Status', style: TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Alert Banner
            if (isExpiringSoon || policy.status.toLowerCase() == 'lapsed')
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.alertTriangle, color: Colors.red, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        policy.status.toLowerCase() == 'lapsed'
                            ? 'Policy has lapsed! Please contact customer.'
                            : 'Expires in $daysUntilExpiry days — Renewal needed immediately!',
                        style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),

            // Policy Details Section
            const Text('Policy Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1D26))),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
              child: Column(
                children: [
                  _buildDetailRow(LucideIcons.tag, 'Policy Type', 'Life Insurance'),
                  const Divider(height: 1),
                  _buildDetailRow(LucideIcons.calendar, 'Start Date', '2023-01-01'), // Placeholder as not in API yet
                  const Divider(height: 1),
                  _buildDetailRow(LucideIcons.calendarClock, 'Expiry / Next Due Date', policy.premiumDueDate ?? 'N/A', isAlert: isExpiringSoon),
                  const Divider(height: 1),
                  _buildDetailRow(LucideIcons.award, 'Maturity Date', policy.maturityDate ?? 'N/A'),
                  const Divider(height: 1),
                  _buildDetailRow(LucideIcons.refreshCw, 'Payment Frequency', 'Annually'), // Placeholder as not in API yet
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Nominee Details Section
            const Text('Nominee Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1D26))),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
              child: Column(
                children: [
                  _buildDetailRow(LucideIcons.user, 'Nominee Name', 'Pending Setup'), // Placeholder
                  const Divider(height: 1),
                  _buildDetailRow(LucideIcons.users, 'Relationship', 'Pending Setup'), // Placeholder
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Customer Details Section
            const Text('Customer Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1A1D26))),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: const Color(0xFF4CAF50),
                    child: Text(
                      policy.customerName.isNotEmpty ? policy.customerName[0].toUpperCase() : 'C',
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(policy.customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1A1D26))),
                        const SizedBox(height: 4),
                        Text(policy.customerPhone, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                        const SizedBox(height: 2),
                        const Text('Client', style: TextStyle(color: Colors.blueGrey, fontSize: 12)),
                      ],
                    ),
                  ),
                  const Icon(LucideIcons.chevronRight, color: Colors.grey),
                ],
              ),
            ),
            const SizedBox(height: 100), // Space for bottom bar
          ],
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(LucideIcons.phoneCall, size: 18),
                label: const Text('Call Customer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(LucideIcons.messageCircle, size: 18),
                label: const Text('Send Reminder'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {bool isAlert = false}) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.grey.shade50, shape: BoxShape.circle),
            child: Icon(icon, size: 16, color: Colors.green.shade600),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: isAlert ? Colors.red : const Color(0xFF1A1D26),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
