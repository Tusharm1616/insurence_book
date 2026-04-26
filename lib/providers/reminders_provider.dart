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
    return ReminderItem(
      customerId: json['customer_id'],
      fullName: json['full_name'],
      phone: json['phone'],
      eventDate: json['event_date'],
      daysRemaining: json['days_remaining'],
      turningAge: json['turning_age'],
      isToday: json['is_today'],
    );
  }
}

final birthdaysProvider = FutureProvider<List<ReminderItem>>((ref) async {
  final res = await apiService.dio.get('/reminders/birthdays');
  final List data = res.data;
  return data.map((e) => ReminderItem.fromJson(e)).toList();
});

final anniversariesProvider = FutureProvider<List<ReminderItem>>((ref) async {
  final res = await apiService.dio.get('/reminders/anniversaries');
  final List data = res.data;
  return data.map((e) => ReminderItem.fromJson(e)).toList();
});
