import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/theme.dart';

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied to clipboard'), duration: Duration(seconds: 1)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact Us', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.grey.shade50,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _contactCard(
              context,
              icon: LucideIcons.phone,
              color: Colors.green,
              title: 'Mobile Number',
              label: 'Agent Support',
              value: '+91 9999999999',
              actionIcon: LucideIcons.phone,
            ),
            const SizedBox(height: 16),
            _contactCard(
              context,
              icon: LucideIcons.mail,
              color: Colors.blue,
              title: 'Email',
              label: 'Agent Support',
              value: 'agent@gmail.com',
              actionIcon: LucideIcons.mail,
            ),
            const SizedBox(height: 16),
            _contactCard(
              context,
              icon: LucideIcons.mapPin,
              color: Colors.orange,
              title: 'Address',
              label: 'Head Office',
              value: 'rajkot, ASSAM',
              actionIcon: null, // Address doesn't have an action icon in the screenshot, only copy
            ),
          ],
        ),
      ),
    );
  }

  Widget _contactCard(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String label,
    required String value,
    IconData? actionIcon,
  }) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(actionIcon != null ? label.contains('Support') ? LucideIcons.headphones : icon : icon, color: Colors.grey, size: 14),
                    const SizedBox(width: 6),
                    Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                    if (actionIcon != null) ...[
                      IconButton(
                        onPressed: () {}, // Action like opening dialer/email
                        icon: Icon(actionIcon, color: AppColors.primary, size: 18),
                        style: IconButton.styleFrom(backgroundColor: AppColors.primary.withValues(alpha: 0.1), shape: const CircleBorder()),
                      ),
                      const SizedBox(width: 8),
                    ],
                    IconButton(
                      onPressed: () => _copyToClipboard(context, value),
                      icon: const Icon(LucideIcons.copy, color: Colors.blueGrey, size: 18),
                      style: IconButton.styleFrom(backgroundColor: Colors.white, shape: const CircleBorder(), side: BorderSide(color: Colors.grey.shade300)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
