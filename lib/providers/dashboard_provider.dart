import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

class ExpiringCounts {
  final int month1;
  final int month2;
  ExpiringCounts({required this.month1, required this.month2});
}

final expiringCountsProvider = FutureProvider<ExpiringCounts>((ref) async {
  final res1 = await apiService.dio.get('/dashboard/expiring-count', queryParameters: {'days': 30});
  final res2 = await apiService.dio.get('/dashboard/expiring-count', queryParameters: {'days': 60});
  
  return ExpiringCounts(
    month1: res1.data['count'] ?? 0,
    month2: res2.data['count'] ?? 0,
  );
});
