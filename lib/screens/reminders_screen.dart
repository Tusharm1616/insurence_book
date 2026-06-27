import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/lucide_compat.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/reminders_provider.dart';

class RemindersScreen extends ConsumerWidget {
  final String type; // 'birthdays' or 'anniversaries'
  
  const RemindersScreen({super.key, required this.type});

  Future<void> _launchWhatsApp(String phone, String name, String type) async {
    final message = (type == 'birthdays' || type == 'birthday')
      ? 'Happy Birthday $name! Wishing you a fantastic day!'
      : 'Happy Anniversary $name! Wishing you many more years of happiness together!';
    
    // Clean phone number and ensure country code
    String cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    if (!cleanPhone.startsWith('91') && cleanPhone.length == 10) {
      cleanPhone = '91$cleanPhone';
    }
    
    // Use https://wa.me/ which is more reliable across devices
    final webUrl = Uri.parse('https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}');
    
    try {
      await launchUrl(webUrl, mode: LaunchMode.externalApplication);
    } catch (e) {
      // Fallback to whatsapp:// scheme
      try {
        final appUrl = Uri.parse('whatsapp://send?phone=$cleanPhone&text=${Uri.encodeComponent(message)}');
        await launchUrl(appUrl, mode: LaunchMode.externalApplication);
      } catch (e2) {
        debugPrint('Could not launch WhatsApp: $e2');
      }
    }
  }

  Future<void> _launchPhone(String phone) async {
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    final url = Uri.parse('tel:$cleanPhone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBirthday = type == 'birthdays' || type == 'birthday';
    final title = isBirthday ? 'Birthday Reminders' : 'Anniversary Reminders';
    final themeColor = isBirthday ? Colors.pink : Colors.red;
    
    final asyncData = isBirthday ? ref.watch(birthdaysProvider) : ref.watch(anniversariesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: themeColor,
        foregroundColor: Colors.white,
      ),
      backgroundColor: const Color(0xFFF5F6FA),
      body: asyncData.when(
        data: (items) => _buildList(items, themeColor),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(LucideIcons.wifiOff, size: 56, color: Colors.grey.shade400),
                const SizedBox(height: 16),
                Text(
                  'Could not load reminders',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  e.toString().replaceAll('Exception: ', ''),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    if (isBirthday) {
                      ref.read(birthdaysProvider.notifier).refresh();
                    } else {
                      ref.read(anniversariesProvider.notifier).refresh();
                    }
                  },
                  icon: const Icon(LucideIcons.refreshCw, size: 16),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildList(List<ReminderItem> items, Color themeColor) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.calendarX, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              (type == 'birthdays' || type == 'birthday')
                  ? 'No birthdays found.\nAdd DOB when creating customers.'
                  : 'No anniversaries found.\nAdd anniversary date when creating customers.',
              style: const TextStyle(color: Colors.grey, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final todayItems    = items.where((i) => i.daysRemaining == 0).toList();
    final weekItems     = items.where((i) => i.daysRemaining > 0 && i.daysRemaining <= 7).toList();
    final monthItems    = items.where((i) => i.daysRemaining > 7 && i.daysRemaining <= 30).toList();
    final laterItems    = items.where((i) => i.daysRemaining > 30).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (todayItems.isNotEmpty) ...[
          _buildSectionHeader('🎉 Today', Colors.green),
          ...todayItems.map((item) => _buildReminderCard(item, themeColor, isToday: true)),
          const SizedBox(height: 8),
        ],
        if (weekItems.isNotEmpty) ...[
          _buildSectionHeader('This Week', Colors.orange),
          ...weekItems.map((item) => _buildReminderCard(item, themeColor, isToday: false)),
          const SizedBox(height: 8),
        ],
        if (monthItems.isNotEmpty) ...[
          _buildSectionHeader('This Month', Colors.blue),
          ...monthItems.map((item) => _buildReminderCard(item, themeColor, isToday: false)),
          const SizedBox(height: 8),
        ],
        if (laterItems.isNotEmpty) ...[
          _buildSectionHeader('Upcoming', Colors.grey.shade600),
          ...laterItems.map((item) => _buildReminderCard(item, themeColor, isToday: false)),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13, letterSpacing: 1),
      ),
    );
  }

  Widget _buildReminderCard(ReminderItem item, Color themeColor, {required bool isToday}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: isToday ? 4 : 1,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: isToday ? Border.all(color: Colors.green, width: 2) : null,
          color: Colors.white,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: themeColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  (type == 'birthdays' || type == 'birthday') ? LucideIcons.cake : LucideIcons.heart,
                  color: themeColor,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.fullName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.eventDate} ${item.turningAge != null ? '(Turning ${item.turningAge})' : ''}',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                    if (!isToday) ...[
                      const SizedBox(height: 2),
                      Text(
                        'In ${item.daysRemaining} days',
                        style: const TextStyle(color: Colors.orange, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ]
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(LucideIcons.phone, color: Colors.blue),
                    onPressed: () => _launchPhone(item.phone),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.messageCircle, color: Colors.green),
                    onPressed: () => _launchWhatsApp(item.phone, item.fullName, type),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
