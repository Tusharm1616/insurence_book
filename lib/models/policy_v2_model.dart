class PolicyV2 {
  final String id; // UUID string
  final int? customerId;
  final String? customerName;
  final String policyNumber;
  final String? insuranceCompany;
  final String insuranceType;
  final DateTime? startDate;
  final DateTime? endDate;
  final double? totalAmount;
  final double? discountAmount;
  final double? finalAmount;
  final String? paymentMode;
  final DateTime? paymentDate;
  final DateTime? inspectionDate;
  final String? inspectionStatus;
  final String? claimStatus;
  final double? claimAmount;
  final String? claimNotes;
  final String? refBy;
  final double? commissionPercent;
  final double? commissionAmount;
  final String? policyPdfUrl;
  final String? lastYearPolicyPdfUrl;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  PolicyV2({
    required this.id,
    this.customerId,
    this.customerName,
    required this.policyNumber,
    this.insuranceCompany,
    required this.insuranceType,
    this.startDate,
    this.endDate,
    this.totalAmount,
    this.discountAmount,
    this.finalAmount,
    this.paymentMode,
    this.paymentDate,
    this.inspectionDate,
    this.inspectionStatus,
    this.claimStatus,
    this.claimAmount,
    this.claimNotes,
    this.refBy,
    this.commissionPercent,
    this.commissionAmount,
    this.policyPdfUrl,
    this.lastYearPolicyPdfUrl,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PolicyV2.fromJson(Map<String, dynamic> json) {
    return PolicyV2(
      id: json['id']?.toString() ?? '',
      customerId: json['customer_id'] is int
          ? json['customer_id']
          : int.tryParse(json['customer_id']?.toString() ?? ''),
      customerName: json['customer_name'] as String?,
      policyNumber: json['policy_number'] as String? ?? '',
      insuranceCompany: json['insurance_company'] as String?,
      insuranceType: json['insurance_type'] as String? ?? 'Other',
      startDate: json['start_date'] != null
          ? DateTime.tryParse(json['start_date'].toString())
          : null,
      endDate: json['end_date'] != null
          ? DateTime.tryParse(json['end_date'].toString())
          : null,
      totalAmount: json['total_amount'] != null
          ? (json['total_amount'] as num).toDouble()
          : null,
      discountAmount: json['discount_amount'] != null
          ? (json['discount_amount'] as num).toDouble()
          : null,
      finalAmount: json['final_amount'] != null
          ? (json['final_amount'] as num).toDouble()
          : null,
      paymentMode: json['payment_mode'] as String?,
      paymentDate: json['payment_date'] != null
          ? DateTime.tryParse(json['payment_date'].toString())
          : null,
      inspectionDate: json['inspection_date'] != null
          ? DateTime.tryParse(json['inspection_date'].toString())
          : null,
      inspectionStatus: json['inspection_status'] as String?,
      claimStatus: json['claim_status'] as String?,
      claimAmount: json['claim_amount'] != null
          ? (json['claim_amount'] as num).toDouble()
          : null,
      claimNotes: json['claim_notes'] as String?,
      refBy: json['ref_by'] as String?,
      commissionPercent: json['commission_percent'] != null
          ? (json['commission_percent'] as num).toDouble()
          : null,
      commissionAmount: json['commission_amount'] != null
          ? (json['commission_amount'] as num).toDouble()
          : null,
      policyPdfUrl: json['policy_pdf_url'] as String?,
      lastYearPolicyPdfUrl: json['last_year_policy_pdf_url'] as String?,
      isActive: json['is_active'] == true || json['is_active'] == 1,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (customerId != null) 'customer_id': customerId,
      if (customerName != null) 'customer_name': customerName,
      'policy_number': policyNumber,
      if (insuranceCompany != null) 'insurance_company': insuranceCompany,
      'insurance_type': insuranceType,
      if (startDate != null)
        'start_date': startDate!.toIso8601String().split('T').first,
      if (endDate != null)
        'end_date': endDate!.toIso8601String().split('T').first,
      if (totalAmount != null) 'total_amount': totalAmount,
      if (discountAmount != null) 'discount_amount': discountAmount,
      if (finalAmount != null) 'final_amount': finalAmount,
      if (paymentMode != null) 'payment_mode': paymentMode,
      if (paymentDate != null)
        'payment_date': paymentDate!.toIso8601String().split('T').first,
      if (inspectionDate != null)
        'inspection_date': inspectionDate!.toIso8601String().split('T').first,
      if (inspectionStatus != null) 'inspection_status': inspectionStatus,
      if (claimStatus != null) 'claim_status': claimStatus,
      if (claimAmount != null) 'claim_amount': claimAmount,
      if (claimNotes != null) 'claim_notes': claimNotes,
      if (refBy != null) 'ref_by': refBy,
      if (commissionPercent != null) 'commission_percent': commissionPercent,
      if (commissionAmount != null) 'commission_amount': commissionAmount,
      if (policyPdfUrl != null) 'policy_pdf_url': policyPdfUrl,
      if (lastYearPolicyPdfUrl != null)
        'last_year_policy_pdf_url': lastYearPolicyPdfUrl,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
