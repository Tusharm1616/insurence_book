import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/bank_details.dart';
import '../services/api_service.dart';

class BankDetailsNotifier extends AsyncNotifier<BankDetails?> {
  @override
  Future<BankDetails?> build() => _fetch();

  Future<BankDetails?> _fetch() async {
    final res = await apiService.dio.get('/api/agent/bank-details');
    return BankDetails.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<bool> updateDetails(BankDetails details) async {
    try {
      await apiService.dio.put('/api/agent/bank-details', data: details.toJson());
      await refresh();
      return true;
    } catch (e) {
      return false;
    }
  }
}

final bankDetailsProvider =
    AsyncNotifierProvider<BankDetailsNotifier, BankDetails?>(
  BankDetailsNotifier.new,
);
