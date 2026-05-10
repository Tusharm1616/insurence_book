import 'package:flutter/material.dart';

// ── Status constants ──────────────────────────────────────────────────────
const kStatusValid       = 'valid';
const kStatusExpiringSoon = 'expiring_soon';
const kStatusExpired     = 'expired';
const kStatusNotSet      = 'not_set';

// ── Per-document status ───────────────────────────────────────────────────
class DocStatus {
  final DateTime? expiryDate;
  final int? daysUntilExpiry;
  final String status; // valid | expiring_soon | expired | not_set

  const DocStatus({
    required this.expiryDate,
    required this.daysUntilExpiry,
    required this.status,
  });

  bool get isExpired      => status == kStatusExpired;
  bool get isExpiringSoon => status == kStatusExpiringSoon;
  bool get isValid        => status == kStatusValid;
  bool get isSet          => status != kStatusNotSet;

  Color get color {
    switch (status) {
      case kStatusExpired:      return const Color(0xFFB71C1C);
      case kStatusExpiringSoon: return const Color(0xFFE65100);
      case kStatusValid:        return const Color(0xFF2E7D32);
      default:                  return const Color(0xFF9E9E9E);
    }
  }

  String get label {
    switch (status) {
      case kStatusExpired:      return 'EXPIRED';
      case kStatusExpiringSoon: return 'EXPIRING SOON';
      case kStatusValid:        return 'VALID';
      default:                  return 'NOT SET';
    }
  }

  String get daysLabel {
    if (daysUntilExpiry == null) return '—';
    if (daysUntilExpiry! < 0) return '${daysUntilExpiry!.abs()} days ago';
    if (daysUntilExpiry == 0) return 'Today';
    return '${daysUntilExpiry!} days left';
  }

  factory DocStatus.fromJson(Map<String, dynamic> json) {
    return DocStatus(
      expiryDate: json['expiry_date'] != null
          ? DateTime.tryParse(json['expiry_date'].toString())
          : null,
      daysUntilExpiry: json['days_until_expiry'] as int?,
      status: json['status'] as String? ?? kStatusNotSet,
    );
  }
}

// ── Main model ────────────────────────────────────────────────────────────
class VehicleDoc {
  final int id;
  final int agentId;
  final int? customerId;
  final String? customerName;
  final String? customerMobile;

  final String vehicleNumber;
  final String vehicleType;
  final String vehicleModel;
  final String manufacturer;
  final String fuelType;
  final int? registrationYear;

  final DocStatus insurance;
  final DocStatus puc;
  final DocStatus rc;
  final DocStatus license;
  final DocStatus fitness;

  final String overallStatus;
  final bool reminderSent;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  const VehicleDoc({
    required this.id,
    required this.agentId,
    this.customerId,
    this.customerName,
    this.customerMobile,
    required this.vehicleNumber,
    required this.vehicleType,
    required this.vehicleModel,
    required this.manufacturer,
    required this.fuelType,
    this.registrationYear,
    required this.insurance,
    required this.puc,
    required this.rc,
    required this.license,
    required this.fitness,
    required this.overallStatus,
    required this.reminderSent,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  // ── Computed ──
  Color get statusColor {
    switch (overallStatus) {
      case kStatusExpired:      return const Color(0xFFB71C1C);
      case kStatusExpiringSoon: return const Color(0xFFE65100);
      default:                  return const Color(0xFF2E7D32);
    }
  }

  String get statusLabel {
    switch (overallStatus) {
      case kStatusExpired:      return 'EXPIRED';
      case kStatusExpiringSoon: return 'EXPIRING SOON';
      default:                  return 'VALID';
    }
  }

  String get displayName =>
      customerName?.isNotEmpty == true ? customerName! : 'No Customer';

  factory VehicleDoc.fromJson(Map<String, dynamic> json) {
    return VehicleDoc(
      id: json['id'] as int,
      agentId: json['agent_id'] as int,
      customerId: json['customer_id'] as int?,
      customerName: json['customer_name'] as String?,
      customerMobile: json['customer_mobile'] as String?,
      vehicleNumber: json['vehicle_number'] as String,
      vehicleType: json['vehicle_type'] as String,
      vehicleModel: json['vehicle_model'] as String,
      manufacturer: json['manufacturer'] as String,
      fuelType: json['fuel_type'] as String,
      registrationYear: json['registration_year'] as int?,
      insurance: DocStatus.fromJson(json['insurance'] as Map<String, dynamic>),
      puc:       DocStatus.fromJson(json['puc']       as Map<String, dynamic>),
      rc:        DocStatus.fromJson(json['rc']         as Map<String, dynamic>),
      license:   DocStatus.fromJson(json['license']   as Map<String, dynamic>),
      fitness:   DocStatus.fromJson(json['fitness']   as Map<String, dynamic>),
      overallStatus: json['overall_status'] as String,
      reminderSent:  json['reminder_sent']  as bool? ?? false,
      notes:         json['notes']          as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toCreateJson() => {
    'vehicle_number':    vehicleNumber,
    'vehicle_type':      vehicleType,
    'vehicle_model':     vehicleModel,
    'manufacturer':      manufacturer,
    'fuel_type':         fuelType,
    if (registrationYear != null) 'registration_year': registrationYear,
    if (customerId != null)       'customer_id':       customerId,
    if (insurance.expiryDate != null) 'insurance_expiry': _fmt(insurance.expiryDate!),
    if (puc.expiryDate != null)       'puc_expiry':       _fmt(puc.expiryDate!),
    if (rc.expiryDate != null)        'rc_expiry':        _fmt(rc.expiryDate!),
    if (license.expiryDate != null)   'license_expiry':   _fmt(license.expiryDate!),
    if (fitness.expiryDate != null)   'fitness_expiry':   _fmt(fitness.expiryDate!),
    if (notes != null)                'notes':            notes,
  };

  static String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

// ── Summary model ─────────────────────────────────────────────────────────
class VehicleDocSummary {
  final int total;
  final int insuranceExpiring;
  final int pucExpiring;
  final int rcExpiring;
  final int licenseExpiring;
  final int fitnessExpiring;
  final int totalExpiringSoon;
  final int totalExpired;
  final int totalValid;

  const VehicleDocSummary({
    required this.total,
    required this.insuranceExpiring,
    required this.pucExpiring,
    required this.rcExpiring,
    required this.licenseExpiring,
    required this.fitnessExpiring,
    required this.totalExpiringSoon,
    required this.totalExpired,
    required this.totalValid,
  });

  factory VehicleDocSummary.fromJson(Map<String, dynamic> json) {
    return VehicleDocSummary(
      total:              json['total']              as int? ?? 0,
      insuranceExpiring:  json['insurance_expiring'] as int? ?? 0,
      pucExpiring:        json['puc_expiring']       as int? ?? 0,
      rcExpiring:         json['rc_expiring']        as int? ?? 0,
      licenseExpiring:    json['license_expiring']   as int? ?? 0,
      fitnessExpiring:    json['fitness_expiring']   as int? ?? 0,
      totalExpiringSoon:  json['total_expiring_soon'] as int? ?? 0,
      totalExpired:       json['total_expired']       as int? ?? 0,
      totalValid:         json['total_valid']         as int? ?? 0,
    );
  }

  factory VehicleDocSummary.empty() => const VehicleDocSummary(
    total: 0, insuranceExpiring: 0, pucExpiring: 0,
    rcExpiring: 0, licenseExpiring: 0, fitnessExpiring: 0,
    totalExpiringSoon: 0, totalExpired: 0, totalValid: 0,
  );
}
