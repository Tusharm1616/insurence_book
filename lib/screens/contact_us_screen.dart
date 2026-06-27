import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/lucide_compat.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme.dart';

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard'), duration: Duration(seconds: 1)),
    );
  }

  Future<void> _launchUrl(BuildContext context, String urlString, {bool isWhatsApp = false}) async {
    final url = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: isWhatsApp ? LaunchMode.externalApplication : LaunchMode.platformDefault);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not perform this action. App may not be installed.'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact Us', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      backgroundColor: AppThemeHelper.scaffoldBg(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              'Get in Touch',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppThemeHelper.textPrimary(context)),
            ),
            const SizedBox(height: 4),
            Text(
              'We\'re here to help you 24×7',
              style: TextStyle(fontSize: 13, color: AppThemeHelper.textSecondary(context)),
            ),
            const SizedBox(height: 20),
            _contactCard(
              context,
              icon: LucideIcons.phoneCall,
              color: AppColors.primary,
              title: '24×7 Agent Support',
              label: 'Primary Number',
              value: '+91 84595 31212',
              actionIcon: LucideIcons.phone,
              onActionTap: () => _launchUrl(context, 'tel:+918459531212'),
              secondaryActionIcon: Icons.wechat,
              onSecondaryActionTap: () =>
                  _launchUrl(context, 'whatsapp://send?phone=918459531212', isWhatsApp: true),
            ),
            const SizedBox(height: 16),
            _contactCard(
              context,
              icon: LucideIcons.mail,
              color: Colors.blue,
              title: 'Email Support',
              label: 'General Queries',
              value: 'support@insurebook.com',
              actionIcon: LucideIcons.mail,
              onActionTap: () => _launchUrl(context, 'mailto:support@insurebook.com'),
            ),
            const SizedBox(height: 16),
            _contactCard(
              context,
              icon: LucideIcons.mapPin,
              color: Colors.orange,
              title: 'Office Address',
              label: 'Head Office',
              value: '123 Business Hub, Pune, Maharashtra',
              actionIcon: LucideIcons.navigation,
              onActionTap: () {},
            ),
            const SizedBox(height: 24),
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
    VoidCallback? onActionTap,
    IconData? secondaryActionIcon,
    VoidCallback? onSecondaryActionTap,
  }) {
    final isDark = AppThemeHelper.isDark(context);
    return Container(
      decoration: BoxDecoration(
        color: AppThemeHelper.cardColor(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppThemeHelper.borderColor(context)),
        boxShadow: isDark
            ? []
            : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppThemeHelper.textPrimary(context)),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppThemeHelper.surfaceColor(context),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: AppThemeHelper.iconMuted(context), size: 14),
                    const SizedBox(width: 6),
                    Text(label, style: TextStyle(color: AppThemeHelper.textSecondary(context), fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        value,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppThemeHelper.textPrimary(context)),
                      ),
                    ),
                    if (actionIcon != null) ...[
                      IconButton(
                        onPressed: onActionTap,
                        icon: Icon(actionIcon, color: AppColors.primary, size: 18),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                          shape: const CircleBorder(),
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                    if (secondaryActionIcon != null) ...[
                      IconButton(
                        onPressed: onSecondaryActionTap,
                        icon: Icon(secondaryActionIcon, color: Colors.green.shade600, size: 18),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.green.withValues(alpha: 0.1),
                          shape: const CircleBorder(),
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                    IconButton(
                      onPressed: () => _copyToClipboard(context, value),
                      icon: Icon(LucideIcons.copy, color: AppThemeHelper.textSecondary(context), size: 18),
                      style: IconButton.styleFrom(
                        backgroundColor: AppThemeHelper.surfaceColor(context),
                        shape: const CircleBorder(),
                        side: BorderSide(color: AppThemeHelper.borderColor(context)),
                      ),
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
