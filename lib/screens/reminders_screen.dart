import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/reminders_provider.dart';

class RemindersScreen extends ConsumerWidget {
  final String type; // 'birthdays' or 'anniversaries'
  
  const RemindersScreen({super.key, required this.type});

  Future<void> _launchWhatsApp(String phone, String name, String type) async {
    final message = type == 'birthdays' 
      ? 'Happy Birthday $name! Wishing you a fantastic day!'
      : 'Happy Anniversary $name! Wishing you many more years of happiness together!';
    
    // Clean phone number
    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    final url = Uri.parse('whatsapp://send?phone=$cleanPhone&text=${Uri.encodeComponent(message)}');
    
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        // Fallback to web
        final webUrl = Uri.parse('https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}');
        if (await canLaunchUrl(webUrl)) {
          await launchUrl(webUrl);
        }
      }
    } catch (e) {
      debugPrint('Could not launch WhatsApp: $e');
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
    final isBirthday = type == 'birthdays';
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
        error: (e, _) => Center(child: Text('Error: $e')),
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
            const Text('No upcoming reminders in next 30 days', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    final todayItems = items.where((i) => i.isToday).toList();
    final upcomingItems = items.where((i) => !i.isToday).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (todayItems.isNotEmpty) ...[
          _buildSectionHeader('Today', Colors.green),
          ...todayItems.map((item) => _buildReminderCard(item, themeColor, isToday: true)),
          const SizedBox(height: 16),
        ],
        if (upcomingItems.isNotEmpty) ...[
          _buildSectionHeader('Upcoming', Colors.grey.shade700),
          ...upcomingItems.map((item) => _buildReminderCard(item, themeColor, isToday: false)),
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
                  type == 'birthdays' ? LucideIcons.cake : LucideIcons.heart,
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
