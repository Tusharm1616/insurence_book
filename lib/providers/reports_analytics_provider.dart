import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

// ── Models ──────────────────────────────────────────────────────────────────

class InsuranceTypeData {
  final String type;
  final int count;
  final double amount;

  InsuranceTypeData({required this.type, required this.count, required this.amount});

  factory InsuranceTypeData.fromJson(Map<String, dynamic> json) {
    return InsuranceTypeData(
      type: json['type'] ?? 'Other',
      count: json['count'] ?? 0,
      amount: (json['amount'] ?? 0).toDouble(),
    );
  }
}

class MonthlyTrendData {
  final String month;
  final double business;
  final double income;

  MonthlyTrendData({required this.month, required this.business, required this.income});

  factory MonthlyTrendData.fromJson(Map<String, dynamic> json) {
    return MonthlyTrendData(
      month: json['month'] ?? '',
      business: (json['business'] ?? 0).toDouble(),
      income: (json['income'] ?? 0).toDouble(),
    );
  }
}

class ReportsDashboard {
  final double totalBusiness;
  final double totalIncome;
  final int policiesSold;
  final int leadsTotal;
  final int leadsConverted;
  final int saleComplete;
  final int salePending;
  final List<InsuranceTypeData> byInsuranceType;
  final List<MonthlyTrendData> monthlyTrend;

  ReportsDashboard({
    required this.totalBusiness,
    required this.totalIncome,
    required this.policiesSold,
    required this.leadsTotal,
    required this.leadsConverted,
    required this.saleComplete,
    required this.salePending,
    required this.byInsuranceType,
    required this.monthlyTrend,
  });

  factory ReportsDashboard.fromJson(Map<String, dynamic> json) {
    return ReportsDashboard(
      totalBusiness: (json['total_business'] ?? 0).toDouble(),
      totalIncome: (json['total_income'] ?? 0).toDouble(),
      policiesSold: json['policies_sold'] ?? 0,
      leadsTotal: json['leads_total'] ?? 0,
      leadsConverted: json['leads_converted'] ?? 0,
      saleComplete: json['sale_complete'] ?? 0,
      salePending: json['sale_pending'] ?? 0,
      byInsuranceType: (json['by_insurance_type'] as List? ?? [])
          .map((e) => InsuranceTypeData.fromJson(e))
          .toList(),
      monthlyTrend: (json['monthly_trend'] as List? ?? [])
          .map((e) => MonthlyTrendData.fromJson(e))
          .toList(),
    );
  }
}

class ReportPolicy {
  final String id;
  final String policyNumber;
  final String customerName;
  final String? customerPhone;
  final String insuranceType;
  final String? insuranceCompany;
  final double amount;
  final double commission;
  final double commissionPercent;
  final String? paymentMode;
  final String? createdAt;

  ReportPolicy({
    required this.id,
    required this.policyNumber,
    required this.customerName,
    this.customerPhone,
    required this.insuranceType,
    this.insuranceCompany,
    required this.amount,
    required this.commission,
    required this.commissionPercent,
    this.paymentMode,
    this.createdAt,
  });

  factory ReportPolicy.fromJson(Map<String, dynamic> json) {
    return ReportPolicy(
      id: json['id'] ?? '',
      policyNumber: json['policy_number'] ?? '',
      customerName: json['customer_name'] ?? 'Unknown',
      customerPhone: json['customer_phone'],
      insuranceType: json['insurance_type'] ?? 'Other',
      insuranceCompany: json['insurance_company'],
      amount: (json['amount'] ?? 0).toDouble(),
      commission: (json['commission'] ?? 0).toDouble(),
      commissionPercent: (json['commission_percent'] ?? 0).toDouble(),
      paymentMode: json['payment_mode'],
      createdAt: json['created_at'],
    );
  }
}

// ── State Notifier for selected month ───────────────────────────────────────

class SelectedMonthNotifier extends Notifier<String> {
  @override
  String build() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  void setMonth(String month) {
    state = month;
  }
}

final selectedMonthProvider = NotifierProvider<SelectedMonthNotifier, String>(
  SelectedMonthNotifier.new,
);

// ── Dashboard Provider ──────────────────────────────────────────────────────

final reportsDashboardProvider = FutureProvider.autoDispose<ReportsDashboard>((ref) async {
  final month = ref.watch(selectedMonthProvider);
  final res = await apiService.dio.get('/api/reports/dashboard', queryParameters: {'month': month});
  return ReportsDashboard.fromJson(res.data);
});

// ── Policies list Provider ──────────────────────────────────────────────────

final reportsPoliciesProvider = FutureProvider.autoDispose<List<ReportPolicy>>((ref) async {
  final month = ref.watch(selectedMonthProvider);
  final res = await apiService.dio.get('/api/reports/policies', queryParameters: {'month': month});
  final data = res.data['policies'] as List? ?? [];
  return data.map((e) => ReportPolicy.fromJson(e)).toList();
});
