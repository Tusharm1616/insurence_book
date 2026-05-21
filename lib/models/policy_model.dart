class Policy {
  final int id;
  final int? customerId;
  final String? customerName;
  final String policyType;
  final String policyNumber;
  final String insuranceCompany;
  final double sumInsured;
  final double premium;
  final DateTime startDate;
  final DateTime expiryDate;
  final DateTime? maturityDate;
  final DateTime? premiumDueDate;
  final String status;           // stored status from backend
  final String? computedStatus;  // date-driven status from backend
  final String? nomineeName;
  final String? nomineeRelation;
  final Map<String, String> extraData;

  Policy({
    required this.id,
    this.customerId,
    this.customerName,
    required this.policyType,
    required this.policyNumber,
    required this.insuranceCompany,
    required this.sumInsured,
    required this.premium,
    required this.startDate,
    required this.expiryDate,
    this.maturityDate,
    this.premiumDueDate,
    this.status = 'active',
    this.computedStatus,
    this.nomineeName,
    this.nomineeRelation,
    this.extraData = const {},
  });

  // ── Date-based booleans ──────────────────────────────────────────────────
  bool get isExpired => expiryDate.isBefore(DateTime.now());
  bool get isExpiringSoon => !isExpired && daysToExpiry <= 30;
  bool get isPremiumDue {
    if (premiumDueDate == null) return false;
    return premiumDueDate!.isBefore(DateTime.now());
  }

  int get daysToExpiry => expiryDate.difference(DateTime.now()).inDays;

  bool get isLifeInsurance =>
      policyType == 'Life Insurance' || policyType == 'Life';

  bool get hasNominee =>
      (nomineeName != null && nomineeName!.isNotEmpty) ||
      (extraData['nomineeName'] != null &&
          extraData['nomineeName']!.isNotEmpty);

  String get effectiveNomineeName =>
      nomineeName?.isNotEmpty == true
          ? nomineeName!
          : extraData['nomineeName'] ?? '';

  String get effectiveNomineeRelation =>
      nomineeRelation?.isNotEmpty == true
          ? nomineeRelation!
          : extraData['nomineeRelation'] ?? '';

  // ── Status resolution ────────────────────────────────────────────────────
  /// The authoritative status to display — prefers backend computed status,
  /// falls back to client-side date logic.
  String get resolvedStatus {
    final s = (computedStatus ?? status).toLowerCase();
    if (s == 'live' || s == 'running') return 'active';
    return s;
  }

  /// Human-readable status label
  String get statusLabel {
    switch (resolvedStatus) {
      case 'active':
        if (isExpired) return 'EXPIRED';
        if (isExpiringSoon) return 'EXPIRING SOON';
        return 'ACTIVE';
      case 'expiring_soon':
        return 'EXPIRING SOON';
      case 'expired':
        return 'EXPIRED';
      case 'premium_due':
        return 'PREMIUM DUE';
      case 'overdue':
        return 'OVERDUE';
      case 'lapsed':
        return 'LAPSED';
      case 'matured':
        return 'MATURED';
      case 'renewed':
        return 'RENEWED';
      case 'cancelled':
        return 'CANCELLED';
      case 'pending':
        return 'PENDING';
      default:
        if (isExpired) return 'EXPIRED';
        if (isExpiringSoon) return 'EXPIRING SOON';
        return 'ACTIVE';
    }
  }

  // ── Status color ─────────────────────────────────────────────────────────
  /// Maps each status to a semantic color for badges and indicators.
  static const Map<String, int> _statusColors = {
    'active':        0xFF2E7D32, // dark green
    'expiring_soon': 0xFFE65100, // deep orange
    'expired':       0xFFB71C1C, // dark red
    'premium_due':   0xFFF57F17, // amber dark
    'overdue':       0xFFD32F2F, // red
    'lapsed':        0xFF616161, // grey
    'matured':       0xFF00695C, // teal
    'renewed':       0xFF1565C0, // blue
    'cancelled':     0xFF4E342E, // brown
    'pending':       0xFF37474F, // blue grey
  };

  int get statusColorValue =>
      _statusColors[resolvedStatus] ?? _statusColors['active']!;

  // ── Serialization ────────────────────────────────────────────────────────
  factory Policy.fromJson(Map<String, dynamic> json) {
    final extraDataRaw = <String, String>{};
    if (json['extra_data'] is Map) {
      (json['extra_data'] as Map).forEach((k, v) {
        extraDataRaw[k.toString()] = v?.toString() ?? '';
      });
    }
    final nomineeName = json['nominee_name'] as String?;
    final nomineeRelation = json['nominee_relation'] as String?;

    // Handle both old (issue_date/expiry_date) and new (start_date/end_date) field names
    final startRaw = json['issue_date'] ?? json['start_date'] ?? json['created_at'];
    final endRaw   = json['expiry_date'] ?? json['end_date'];

    // Fallback dates so we never crash on missing fields
    final startDate  = startRaw != null ? DateTime.tryParse(startRaw.toString()) ?? DateTime.now() : DateTime.now();
    final expiryDate = endRaw   != null ? DateTime.tryParse(endRaw.toString())   ?? DateTime.now().add(const Duration(days: 365)) : DateTime.now().add(const Duration(days: 365));

    return Policy(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      customerId: json['customer_id'] is int
          ? json['customer_id']
          : int.tryParse(json['customer_id']?.toString() ?? '') ,
      customerName: json['customer_name'] as String?,
      policyType: json['policy_type'] ?? json['insurance_type'] ?? 'Other',
      policyNumber: (json['policy_number'] as String? ?? '').trim(),
      insuranceCompany: json['insurer_name'] as String? ?? 'Unknown',
      sumInsured: (json['sum_assured'] ?? json['sum_insured'] as num?)?.toDouble() ?? 0.0,
      premium: (json['premium_amount'] as num?)?.toDouble() ?? 0.0,
      startDate: startDate,
      expiryDate: expiryDate,
      maturityDate: json['maturity_date'] != null
          ? DateTime.tryParse(json['maturity_date'].toString())
          : null,
      premiumDueDate: json['premium_due_date'] != null
          ? DateTime.tryParse(json['premium_due_date'].toString())
          : null,
      status: (json['status'] as String? ?? 'active').toLowerCase(),
      computedStatus: json['computed_status'] as String?,
      nomineeName: nomineeName,
      nomineeRelation: nomineeRelation,
      extraData: extraDataRaw,
    );
  }

  String get mappedPolicyType {
    if (policyType.startsWith('Motor Insurance')) return 'Motor';
    if (policyType.contains('Motor')) return 'Motor';
    if (policyType == 'Health Insurance') return 'Health';
    if (policyType == 'Life Insurance') return 'Life';
    if (policyType == 'Travel Insurance') return 'Travel';
    if (policyType == 'Home Insurance') return 'Home';
    if (policyType == 'Business Insurance') return 'Business';
    if (policyType == 'Shop / Commercial') return 'Shop/Commercial';
    if (policyType == 'Two Wheeler') return 'Two Wheeler';
    if (policyType == 'Accident Insurance') return 'Accident';
    if (policyType == 'Term Insurance') return 'Term';
    if (policyType == 'WC Insurance') return 'WC Insurance';
    return policyType;
  }

  Map<String, dynamic> toJson() {
    return {
      if (customerId != null) 'customer_id': customerId,
      'policy_type': mappedPolicyType,
      'policy_number': policyNumber.isNotEmpty ? policyNumber : null,
      'insurer_name': insuranceCompany,
      'plan_name': extraData['planName'] ?? extraData['policyType'] ?? mappedPolicyType,
      'sum_assured': sumInsured,
      'premium_amount': premium,
      // Send both field name variants so either endpoint accepts it
      'start_date': startDate.toIso8601String().split('T').first,
      'end_date': expiryDate.toIso8601String().split('T').first,
      'issue_date': startDate.toIso8601String().split('T').first,
      'expiry_date': expiryDate.toIso8601String().split('T').first,
      if (maturityDate != null)
        'maturity_date': maturityDate!.toIso8601String().split('T').first,
      if (premiumDueDate != null)
        'premium_due_date': premiumDueDate!.toIso8601String().split('T').first,
      'status': status.toLowerCase(),
      if (nomineeName != null && nomineeName!.isNotEmpty)
        'nominee_name': nomineeName,
      if (nomineeRelation != null && nomineeRelation!.isNotEmpty)
        'nominee_relation': nomineeRelation,
      if (extraData['notes'] != null) 'notes': extraData['notes'],
    };
  }
}

/// Insurer name → standard display name mapping
const Map<String, String> kStandardInsurerNames = {
  'lic': 'LIC',
  'hdfc ergo': 'HDFC Ergo',
  'hdfc life': 'HDFC Life',
  'sbi life': 'SBI Life',
  'sbi general': 'SBI General',
  'tata aia': 'Tata AIA',
  'icici lombard': 'ICICI Lombard',
  'icici prudential': 'ICICI Prudential',
  'star health': 'Star Health',
  'bajaj allianz': 'Bajaj Allianz',
  'reliance general': 'Reliance General',
  'new india assurance': 'New India Assurance',
  'national insurance': 'National Insurance',
  'digit insurance': 'Digit Insurance',
  'acko general': 'Acko General',
  'niva bupa': 'Niva Bupa',
  'care health': 'Care Health',
};

/// Full list for dropdowns
const List<String> kInsuranceCompanies = [
  'LIC',
  'HDFC Life',
  'HDFC Ergo',
  'SBI Life',
  'SBI General',
  'Tata AIA',
  'ICICI Lombard',
  'ICICI Prudential',
  'Star Health',
  'Bajaj Allianz',
  'Reliance General',
  'New India Assurance',
  'United India Insurance',
  'National Insurance',
  'Oriental Insurance',
  'Kotak Mahindra Life',
  'Max Life',
  'PNB MetLife',
  'Birla Sun Life',
  'Canara HSBC',
  'Future Generali',
  'Niva Bupa',
  'Care Health',
  'Aditya Birla Health',
  'ManipalCigna',
  'Digit Insurance',
  'Acko General',
  'Royal Sundaram',
  'Shriram General',
  'Cholamandalam',
];
