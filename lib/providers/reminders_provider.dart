import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

class ReminderItem {
  final int customerId;
  final String fullName;
  final String phone;
  final String eventDate;
  final int daysRemaining;
  final int? turningAge;
  final bool isToday;

  ReminderItem({
    required this.customerId,
    required this.fullName,
    required this.phone,
    required this.eventDate,
    required this.daysRemaining,
    this.turningAge,
    required this.isToday,
  });

  factory ReminderItem.fromJson(Map<String, dynamic> json) {
    final days = json['days_remaining'] ?? 0;
    return ReminderItem(
      customerId: json['customer_id'] ?? 0,
      fullName: json['full_name'] ?? 'Unknown',
      phone: json['phone'] ?? '',
      eventDate: json['event_date']?.toString() ?? '',
      daysRemaining: days,
      turningAge: json['turning_age'],
      isToday: json['is_today'] == true || days == 0,
    );
  }
}

final birthdaysProvider = FutureProvider<List<ReminderItem>>((ref) async {
  final res = await apiService.dio.get('/api/reminders/birthdays');
  // Backend returns a flat list of ReminderItem objects
  final List data = res.data is List ? res.data : [];
  return data.map((e) => ReminderItem.fromJson(e)).toList();
});

final anniversariesProvider = FutureProvider<List<ReminderItem>>((ref) async {
  final res = await apiService.dio.get('/api/reminders/anniversaries');
  // Backend returns a flat list of ReminderItem objects
  final List data = res.data is List ? res.data : [];
  return data.map((e) => ReminderItem.fromJson(e)).toList();
});
