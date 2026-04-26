import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import 'package:dio/dio.dart';
import 'dart:io';
import '../services/api_service.dart';

class MotorCalcRequest {
  final String vehicleType;
  final int cubicCapacity;
  final int manufactureYear;
  final double idv;
  final double ncbPercent;
  final List<String> addOns;

  MotorCalcRequest({
    required this.vehicleType,
    required this.cubicCapacity,
    required this.manufactureYear,
    required this.idv,
    required this.ncbPercent,
    required this.addOns,
  });

  Map<String, dynamic> toJson() => {
    'vehicle_type': vehicleType,
    'cubic_capacity': cubicCapacity,
    'manufacture_year': manufactureYear,
    'idv': idv,
    'ncb_percent': ncbPercent,
    'add_ons': addOns,
  };
}

class MotorCalcResponse {
  final double baseOd;
  final double ncbDiscount;
  final double totalOd;
  final double totalTp;
  final double addOnsTotal;
  final double netPremium;
  final double gst;
  final double finalPremium;

  MotorCalcResponse.fromJson(Map<String, dynamic> json)
      : baseOd = json['base_od']?.toDouble() ?? 0,
        ncbDiscount = json['ncb_discount']?.toDouble() ?? 0,
        totalOd = json['total_od']?.toDouble() ?? 0,
        totalTp = json['total_tp']?.toDouble() ?? 0,
        addOnsTotal = json['add_ons_total']?.toDouble() ?? 0,
        netPremium = json['net_premium']?.toDouble() ?? 0,
        gst = json['gst']?.toDouble() ?? 0,
        finalPremium = json['final_premium']?.toDouble() ?? 0;
}

class MotorCalculatorNotifier extends Notifier<AsyncValue<MotorCalcResponse?>> {
  @override
  AsyncValue<MotorCalcResponse?> build() {
    return const AsyncValue.data(null);
  }

  Future<void> calculatePremium(MotorCalcRequest req) async {
    state = const AsyncValue.loading();
    try {
      final res = await apiService.dio.post('/motor/calculate-premium', data: req.toJson());
      state = AsyncValue.data(MotorCalcResponse.fromJson(res.data));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<String?> generateQuotePdf(MotorCalcRequest req) async {
    try {
      final res = await apiService.dio.post(
        '/motor/generate-quote-pdf', 
        data: req.toJson(),
        options: Options(responseType: ResponseType.bytes),
      );
      
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/Motor_Insurance_Quote_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await file.writeAsBytes(res.data);
      return file.path;
    } catch (e) {
      return null;
    }
  }
}

final motorCalculatorProvider = NotifierProvider<MotorCalculatorNotifier, AsyncValue<MotorCalcResponse?>>(
  MotorCalculatorNotifier.new,
);
