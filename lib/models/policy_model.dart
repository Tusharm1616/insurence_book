class Policy {
  final int id;
  final int? customerId;
  final String policyType; // 'Life Insurance', 'Health Insurance', etc.
  final String policyNumber;
  final String insuranceCompany;
  final double sumInsured;
  final double premium;
  final DateTime startDate;
  final DateTime expiryDate;
  final Map<String, String> extraData;

  Policy({
    required this.id,
    this.customerId,
    required this.policyType,
    required this.policyNumber,
    required this.insuranceCompany,
    required this.sumInsured,
    required this.premium,
    required this.startDate,
    required this.expiryDate,
    this.extraData = const {},
  });

  bool get isExpired => expiryDate.isBefore(DateTime.now());

  int get daysToExpiry => expiryDate.difference(DateTime.now()).inDays;

  bool get isExpiringSoon => !isExpired && daysToExpiry <= 30;

  bool get isLifeInsurance => policyType == 'Life Insurance';

  String get statusLabel {
    if (isExpired) return 'EXPIRED';
    if (isExpiringSoon) return 'EXPIRING SOON';
    return 'LIVE';
  }

  factory Policy.fromJson(Map<String, dynamic> json) {
    return Policy(
      id: json['id'],
      customerId: json['customer_id'],
      policyType: json['policy_type'] ?? json['insurance_type'] ?? 'Other',
      policyNumber: json['policy_number'],
      insuranceCompany: json['insurer_name'],
      sumInsured: (json['sum_assured'] as num).toDouble(),
      premium: (json['premium_amount'] as num).toDouble(),
      startDate: DateTime.parse(json['issue_date']),
      expiryDate: DateTime.parse(json['expiry_date']),
    );
  }

  String get mappedPolicyType {
    if (policyType.startsWith('Motor Insurance')) return 'Motor';
    if (policyType == 'Health Insurance') return 'Health';
    if (policyType == 'Life Insurance') return 'Life';
    if (policyType == 'Travel Insurance') return 'Travel';
    if (policyType == 'Home Insurance') return 'Home';
    if (policyType == 'Business Insurance') return 'Business';
    if (policyType == 'Shop / Commercial') return 'Shop/Commercial';
    if (policyType == 'Two Wheeler') return 'Two Wheeler';
    if (policyType == 'Accident Insurance') return 'Accident';
    if (policyType == 'Term Insurance') return 'Term';
    return policyType;
  }

  Map<String, dynamic> toJson() {
    return {
      'customer_id': customerId,
      'policy_type': mappedPolicyType,
      'policy_number': policyNumber,
      'insurer_name': insuranceCompany,
      'plan_name': 'Default Plan',
      'sum_assured': sumInsured,
      'premium_amount': premium,
      'issue_date': startDate.toIso8601String().split('T').first,
      'expiry_date': expiryDate.toIso8601String().split('T').first,
      'status': isExpired ? 'Expired' : 'Active',
      'extra_data': extraData,
    };
  }
}
