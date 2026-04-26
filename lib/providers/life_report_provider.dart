import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

class LifeReportSummary {
  final int live;
  final int premiumHoliday;
  final int premiumPaidup;
  final int upcomingMaturity;
  final int matured;
  final int lapsed;

  LifeReportSummary({
    required this.live,
    required this.premiumHoliday,
    required this.premiumPaidup,
    required this.upcomingMaturity,
    required this.matured,
    required this.lapsed,
  });

  factory LifeReportSummary.fromJson(Map<String, dynamic> json) {
    return LifeReportSummary(
      live: json['live'] ?? 0,
      premiumHoliday: json['premium_holiday'] ?? 0,
      premiumPaidup: json['premium_paidup'] ?? 0,
      upcomingMaturity: json['upcoming_maturity'] ?? 0,
      matured: json['matured'] ?? 0,
      lapsed: json['lapsed'] ?? 0,
    );
  }
}

final lifeReportProvider = FutureProvider<LifeReportSummary>((ref) async {
  final res = await apiService.dio.get('/life-insurance/report-summary');
  return LifeReportSummary.fromJson(res.data);
});
