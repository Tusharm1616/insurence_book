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
    final days = (json['days_remaining'] as num?)?.toInt() ?? 0;
    return ReminderItem(
      customerId: (json['customer_id'] as num?)?.toInt() ?? 0,
      fullName: json['full_name']?.toString() ?? 'Unknown',
      phone: json['phone']?.toString() ?? '',
      eventDate: json['event_date']?.toString() ?? '',
      daysRemaining: days,
      turningAge: (json['turning_age'] as num?)?.toInt(),
      isToday: json['is_today'] == true || days == 0,
    );
  }
}

// ── Birthday Notifier ─────────────────────────────────────────────────────────
class BirthdaysNotifier extends AsyncNotifier<List<ReminderItem>> {
  @override
  Future<List<ReminderItem>> build() => _fetch();

  Future<List<ReminderItem>> _fetch() async {
    final res = await apiService.dio.get('/api/reminders/birthdays');
    final List data = res.data is List ? res.data as List : [];
    return data
        .map((e) => ReminderItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetch);
  }
}

final birthdaysProvider =
    AsyncNotifierProvider<BirthdaysNotifier, List<ReminderItem>>(
  BirthdaysNotifier.new,
);

// ── Anniversary Notifier ──────────────────────────────────────────────────────
class AnniversariesNotifier extends AsyncNotifier<List<ReminderItem>> {
  @override
  Future<List<ReminderItem>> build() => _fetch();

  Future<List<ReminderItem>> _fetch() async {
    final res = await apiService.dio.get('/api/reminders/anniversaries');
    final List data = res.data is List ? res.data as List : [];
    return data
        .map((e) => ReminderItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetch);
  }
}

final anniversariesProvider =
    AsyncNotifierProvider<AnniversariesNotifier, List<ReminderItem>>(
  AnniversariesNotifier.new,
);
