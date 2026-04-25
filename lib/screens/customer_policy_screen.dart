import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/theme.dart';
import '../models/policy_model.dart';
import '../providers/policy_provider.dart';

class CustomerPolicyScreen extends ConsumerWidget {
  final int? customerId;
  final String? customerName;

  const CustomerPolicyScreen({super.key, this.customerId, this.customerName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allPolicies = ref.watch(policyProvider);
    final policies = customerId != null
        ? allPolicies.where((p) => p.customerId == customerId).toList()
        : allPolicies;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          customerName != null ? '${customerName!}\'s Policies' : 'All Policies',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: policies.isEmpty
          ? _buildEmpty(context)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: policies.length,
              itemBuilder: (context, index) => _buildPolicyCard(context, policies[index]),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/add_policy'),
        backgroundColor: AppColors.primary,
        icon: const Icon(LucideIcons.plus, color: Colors.white),
        label: const Text('Add Policy', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.shieldOff, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('No Policies Found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          const Text('Add a policy using the button below', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/add_policy'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            icon: const Icon(LucideIcons.plus),
            label: const Text('Add First Policy'),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicyCard(BuildContext context, Policy policy) {
    final statusColor = policy.isExpired
        ? Colors.red
        : policy.isExpiringSoon
            ? Colors.orange
            : Colors.green;

    final policyIcon = _iconForType(policy.policyType);
    final policyColor = _colorForType(policy.policyType);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: policyColor.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: policyColor.withValues(alpha: 0.15), shape: BoxShape.circle),
                  child: Icon(policyIcon, color: policyColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(policy.policyType, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(policy.policyNumber.isNotEmpty ? 'Policy #${policy.policyNumber}' : 'No Policy Number', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                  child: Text(policy.statusLabel, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          // Details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _detailRow(LucideIcons.building2, 'Company', policy.insuranceCompany.isNotEmpty ? policy.insuranceCompany : 'N/A'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: _detailRow(LucideIcons.indianRupee, 'Sum Insured', '₹${_formatAmount(policy.sumInsured)}')),
                    Expanded(child: _detailRow(LucideIcons.dollarSign, 'Premium', '₹${_formatAmount(policy.premium)}/yr')),
                  ],
                ),
                const Divider(height: 20),
                Row(
                  children: [
                    Expanded(child: _dateBox('Start Date', policy.startDate, Colors.blue)),
                    const SizedBox(width: 12),
                    Expanded(child: _dateBox('Expiry Date', policy.expiryDate, statusColor)),
                  ],
                ),
                if (policy.isExpired) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.shade200)),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.alertTriangle, color: Colors.red, size: 16),
                        const SizedBox(width: 8),
                        Text('Expired ${policy.daysToExpiry.abs()} days ago — Please renew!', style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ] else if (policy.isExpiringSoon) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.orange.shade200)),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.clock, color: Colors.orange, size: 16),
                        const SizedBox(width: 8),
                        Text('Expiring in ${policy.daysToExpiry} days — Renewal due!', style: const TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }

  Widget _dateBox(String label, DateTime date, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.06), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withValues(alpha: 0.2))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text('${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'Life Insurance': return LucideIcons.heart;
      case 'Health Insurance': return LucideIcons.plus;
      case 'Motor Insurance': return LucideIcons.car;
      case 'WC Insurance': return LucideIcons.briefcase;
      default: return LucideIcons.shield;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'Life Insurance': return Colors.pink;
      case 'Health Insurance': return Colors.green;
      case 'Motor Insurance': return Colors.orange;
      case 'WC Insurance': return Colors.purple;
      default: return Colors.blueGrey;
    }
  }

  String _formatAmount(double amount) {
    if (amount >= 100000) return '${(amount / 100000).toStringAsFixed(1)}L';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(1)}K';
    return amount.toStringAsFixed(0);
  }
}
