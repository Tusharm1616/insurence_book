import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';

class SettingScreen extends ConsumerStatefulWidget {
  const SettingScreen({super.key});

  @override
  ConsumerState<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends ConsumerState<SettingScreen> {
  bool _notificationsEnabled = true;

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(LucideIcons.alertTriangle, color: Colors.red),
            SizedBox(width: 8),
            Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text('Are you sure you want to logout of your agent account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              await ref.read(authProvider.notifier).logout();
              if (!context.mounted) return;
              Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(themeProvider) == ThemeMode.dark;

    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Agent Profile Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).dividerColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: authState.isLoading 
                ? const Center(child: CircularProgressIndicator())
                : Row(
                    children: [
                      CircleAvatar(
                        radius: 32,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                        child: const Icon(LucideIcons.user, size: 32, color: AppColors.primary),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  user?.fullName ?? 'Agent Name', 
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyLarge?.color)
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.verified, color: Colors.blue, size: 18),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Agent ID: AGT-2026-${user?.id ?? "???"}', 
                              style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user?.email ?? user?.username ?? 'email@example.com', 
                              style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 13)
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
            ),
            const SizedBox(height: 24),

            // Preferences
            _buildSectionHeader('Preferences'),
            _toggleTile(
              icon: LucideIcons.bell,
              color: Colors.amber,
              title: 'Push Notifications',
              subtitle: 'Enable or disable alerts',
              value: _notificationsEnabled,
              onChanged: (val) => setState(() => _notificationsEnabled = val),
            ),
            _toggleTile(
              icon: LucideIcons.moon,
              color: Colors.indigo,
              title: 'Dark Mode',
              subtitle: 'Switch to dark theme',
              value: isDarkMode,
              onChanged: (val) => ref.read(themeProvider.notifier).toggleTheme(val),
            ),
            const SizedBox(height: 16),

            // Settings Options
            _buildSectionHeader('Account & Management'),
            _settingTile(context, LucideIcons.lock, Colors.orange, 'Change Password', 'Update your login password', '/change_password'),
            _settingTile(context, LucideIcons.landmark, Colors.blue, 'Bank Details', 'Your bank account information', '/bank_details'),
            _settingTile(context, LucideIcons.flag, Colors.purple, 'Banner Management', 'Manage promotional banners', '/banner_settings'),
            
            const SizedBox(height: 16),
            _buildSectionHeader('Support & Legal'),
            _settingTile(context, LucideIcons.headphones, Colors.teal, 'Contact Us', '24x7 Agent Helpdesk', '/contact_us'),
            _settingTile(context, LucideIcons.fileText, Colors.brown, 'Terms & Conditions', 'View privacy and policies', '/terms'),

            const SizedBox(height: 32),

            // App Version
            Text('InsureBook CRM v1.0.0', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 12, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            // Logout Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showLogoutDialog,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF44336),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                icon: const Icon(LucideIcons.logOut, color: Colors.white),
                label: const Text('Logout Securely', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
      ),
    );
  }

  Widget _toggleTile({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        secondary: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text(subtitle, style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 12)),
        value: value,
        activeThumbColor: AppColors.primary,
        onChanged: onChanged,
      ),
    );
  }

  Widget _settingTile(BuildContext context, IconData icon, Color color, String title, String subtitle, String route) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text(subtitle, style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 12)),
        trailing: Icon(LucideIcons.chevronRight, color: Theme.of(context).textTheme.bodyMedium?.color, size: 20),
        onTap: () => Navigator.pushNamed(context, route),
      ),
    );
  }
}
