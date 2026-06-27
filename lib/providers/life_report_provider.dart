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
  final res = await apiService.dio.get('/api/life-insurance/report-summary');
  return LifeReportSummary.fromJson(res.data);
});

/// Life Insurance Report from the new /api/reports/life-insurance endpoint
class LifeInsuranceReport {
  final int totalPolicies;
  final double totalPremium;
  final int activePolicies;
  final int expiredPolicies;
  final int claimsFiled;

  LifeInsuranceReport({
    required this.totalPolicies,
    required this.totalPremium,
    required this.activePolicies,
    required this.expiredPolicies,
    required this.claimsFiled,
  });

  factory LifeInsuranceReport.fromJson(Map<String, dynamic> json) {
    return LifeInsuranceReport(
      totalPolicies: json['total_policies'] ?? 0,
      totalPremium: (json['total_premium'] ?? 0).toDouble(),
      activePolicies: json['active_policies'] ?? 0,
      expiredPolicies: json['expired_policies'] ?? 0,
      claimsFiled: json['claims_filed'] ?? 0,
    );
  }
}

final lifeInsuranceReportProvider = FutureProvider<LifeInsuranceReport>((ref) async {
  final res = await apiService.dio.get('/api/reports/life-insurance');
  return LifeInsuranceReport.fromJson(res.data);
});
