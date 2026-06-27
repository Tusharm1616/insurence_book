import 'package:flutter/material.dart';
import '../utils/lucide_compat.dart';
import '../models/customer_model.dart';
import 'add_policy_wizard.dart';
import 'motor_subtypes_screen.dart';
import 'add_family_member_screen.dart';
import 'add_corporate_member_screen.dart';

const Color _teal = Color(0xFF0D6B7A);

class CustomerOptionsScreen extends StatelessWidget {
  final Customer customer;

  const CustomerOptionsScreen({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text('Customer Options', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: _teal,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Go to Dashboard ──────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/dashboard', (r) => false),
                icon: const Icon(Icons.home, color: Colors.white),
                label: const Text('Go to Dashboard', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── What would you like to do next? ──────────────────────────
            const Text(
              'What would you like to do next?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 12),

            _optionTile(
              context,
              icon: Icons.group,
              iconBg: Colors.green.shade50,
              iconColor: Colors.green,
              title: 'Add Family Member',
              subtitle: 'Add family members to this customer',
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => AddFamilyMemberScreen(customer: customer),
              )),
            ),
            const SizedBox(height: 10),
            _optionTile(
              context,
              icon: Icons.business,
              iconBg: Colors.blue.shade50,
              iconColor: _teal,
              title: 'Add Corporate Member',
              subtitle: 'Add corporate members to this customer',
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => AddCorporateMemberScreen(customer: customer),
              )),
            ),

            const SizedBox(height: 24),
            // ── Add Insurance Policy ──────────────────────────────────────
            Text(
              'Add Insurance Policy',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _teal),
            ),
            const SizedBox(height: 12),

            _policyTile(
              context,
              icon: Icons.favorite,
              iconBg: Colors.red.shade50,
              iconColor: Colors.red,
              title: 'Life Insurance',
              subtitle: 'Add life insurance policy',
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => AddPolicyWizard(
                  policyType: 'Life Insurance',
                  color: Colors.pink,
                  icon: LucideIcons.heart,
                  isMotor: false,
                  prefilledCustomerId: customer.id,
                  prefilledCustomerName: customer.fullName,
                ),
              )),
            ),
            const SizedBox(height: 10),
            _policyTile(
              context,
              icon: Icons.add_box,
              iconBg: Colors.green.shade50,
              iconColor: Colors.green,
              title: 'Health Insurance',
              subtitle: 'Add health insurance policy',
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => AddPolicyWizard(
                  policyType: 'Health Insurance',
                  color: Colors.green,
                  icon: LucideIcons.activity,
                  isMotor: false,
                  prefilledCustomerId: customer.id,
                  prefilledCustomerName: customer.fullName,
                ),
              )),
            ),
            const SizedBox(height: 10),
            _policyTile(
              context,
              icon: Icons.directions_car,
              iconBg: Colors.orange.shade50,
              iconColor: Colors.orange,
              title: 'Motor Insurance',
              subtitle: 'Add motor insurance policy',
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => MotorSubtypesScreen(
                  prefilledCustomerId: customer.id,
                  prefilledCustomerName: customer.fullName,
                ),
              )),
            ),
            const SizedBox(height: 10),
            _policyTile(
              context,
              icon: Icons.work,
              iconBg: Colors.purple.shade50,
              iconColor: Colors.purple,
              title: 'WC Insurance',
              subtitle: 'Add workmen compensation policy',
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => AddPolicyWizard(
                  policyType: 'WC Insurance',
                  color: Colors.purple,
                  icon: LucideIcons.briefcase,
                  isMotor: false,
                  prefilledCustomerId: customer.id,
                  prefilledCustomerName: customer.fullName,
                ),
              )),
            ),
            const SizedBox(height: 10),
            _policyTile(
              context,
              icon: Icons.shield,
              iconBg: Colors.grey.shade100,
              iconColor: Colors.grey.shade700,
              title: 'Other Insurance',
              subtitle: 'Add other insurance policy',
              onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => AddPolicyWizard(
                  policyType: 'Other Insurance',
                  color: Colors.blueGrey,
                  icon: LucideIcons.shieldCheck,
                  isMotor: false,
                  prefilledCustomerId: customer.id,
                  prefilledCustomerName: customer.fullName,
                ),
              )),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _optionTile(
    BuildContext context, {
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: iconColor, size: 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: iconColor)),
                  const SizedBox(height: 3),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: iconColor, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _policyTile(
    BuildContext context, {
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: iconColor.withValues(alpha: 0.15)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: iconColor)),
                  const SizedBox(height: 3),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: iconColor, size: 20),
          ],
        ),
      ),
    );
  }
}
