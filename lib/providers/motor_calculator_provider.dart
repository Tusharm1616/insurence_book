import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import '../services/api_service.dart';

class MotorCalcPremiumRequest {
  final String vehicleType;
  final String fuelType;
  final int yearOfManufacture;
  final String ccCategory;
  final double idv;
  final double ncbPercent;
  final List<String> addons;
  final String customerName;
  final String vehicleRegNo;

  MotorCalcPremiumRequest({
    required this.vehicleType,
    required this.fuelType,
    required this.yearOfManufacture,
    required this.ccCategory,
    required this.idv,
    required this.ncbPercent,
    required this.addons,
    required this.customerName,
    required this.vehicleRegNo,
  });

  Map<String, dynamic> toJson() => {
    'vehicle_type': vehicleType,
    'fuel_type': fuelType,
    'year_of_manufacture': yearOfManufacture,
    'cc_category': ccCategory,
    'idv': idv,
    'ncb_percent': ncbPercent,
    'addons': addons,
    'customer_name': customerName,
    'vehicle_reg_no': vehicleRegNo,
  };
}

class MotorCalcPremiumResponse {
  final double odBeforeNcb;
  final double ncbDiscount;
  final double odPremium;
  final double tpPremium;
  final Map<String, dynamic> addonBreakdown;
  final double addonsTotal;
  final double subtotal;
  final double gst;
  final double totalPremium;
  final double idv;
  final int vehicleAge;
  final double ncbPercent;
  final String vehicleType;
  final String quoteReference;

  MotorCalcPremiumResponse.fromJson(Map<String, dynamic> json)
      : odBeforeNcb = json['od_before_ncb']?.toDouble() ?? 0,
        ncbDiscount = json['ncb_discount']?.toDouble() ?? 0,
        odPremium = json['od_premium']?.toDouble() ?? 0,
        tpPremium = json['tp_premium']?.toDouble() ?? 0,
        addonBreakdown = json['addon_breakdown'] ?? {},
        addonsTotal = json['addons_total']?.toDouble() ?? 0,
        subtotal = json['subtotal']?.toDouble() ?? 0,
        gst = json['gst']?.toDouble() ?? 0,
        totalPremium = json['total_premium']?.toDouble() ?? 0,
        idv = json['idv']?.toDouble() ?? 0,
        vehicleAge = json['vehicle_age'] ?? 0,
        ncbPercent = json['ncb_percent']?.toDouble() ?? 0,
        vehicleType = json['vehicle_type'] ?? '',
        quoteReference = json['quote_reference'] ?? '';
}

class QuotePdfRequest {
  final MotorCalcPremiumRequest req;
  final MotorCalcPremiumResponse res;

  QuotePdfRequest({required this.req, required this.res});

  Map<String, dynamic> toJson() {
    final json = req.toJson();
    json.addAll({
      'od_before_ncb': res.odBeforeNcb,
      'ncb_discount': res.ncbDiscount,
      'od_premium': res.odPremium,
      'tp_premium': res.tpPremium,
      'addon_breakdown': res.addonBreakdown,
      'addons_total': res.addonsTotal,
      'subtotal': res.subtotal,
      'gst': res.gst,
      'total_premium': res.totalPremium,
      'quote_reference': res.quoteReference,
    });
    return json;
  }
}

class MotorCalculatorNotifier extends Notifier<AsyncValue<MotorCalcPremiumResponse?>> {
  @override
  AsyncValue<MotorCalcPremiumResponse?> build() {
    return const AsyncValue.data(null);
  }

  Future<void> calculatePremium(MotorCalcPremiumRequest req) async {
    state = const AsyncValue.loading();
    try {
      final res = await apiService.dio.post('/api/motor/calculate-premium', data: req.toJson());
      state = AsyncValue.data(MotorCalcPremiumResponse.fromJson(res.data));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<String?> generateQuotePdf(MotorCalcPremiumRequest requestParams) async {
    final currentState = state.value;
    if (currentState == null) return null;

    try {
      final pdfReq = QuotePdfRequest(req: requestParams, res: currentState);
      final res = await apiService.dio.post(
        '/api/motor/generate-quote-pdf', 
        data: pdfReq.toJson(),
        options: Options(responseType: ResponseType.bytes),
      );
      
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/Motor_Quote_${currentState.quoteReference}.pdf');
      await file.writeAsBytes(res.data);
      return file.path;
    } catch (e) {
      return null;
    }
  }
}

final motorCalculatorProvider = NotifierProvider<MotorCalculatorNotifier, AsyncValue<MotorCalcPremiumResponse?>>(
  MotorCalculatorNotifier.new,
);
