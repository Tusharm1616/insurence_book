class BankDetails {
  final String? upiId;
  final String? bankName;
  final String? accountNumber;
  final String? ifscCode;
  final String? branchName;
  final String? qrCodeUrl;

  BankDetails({
    this.upiId,
    this.bankName,
    this.accountNumber,
    this.ifscCode,
    this.branchName,
    this.qrCodeUrl,
  });

  factory BankDetails.fromJson(Map<String, dynamic> json) {
    return BankDetails(
      upiId: json['upi_id'] as String?,
      bankName: json['bank_name'] as String?,
      accountNumber: json['account_number'] as String?,
      ifscCode: json['ifsc_code'] as String?,
      branchName: json['branch_name'] as String?,
      qrCodeUrl: json['qr_code_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'upi_id': upiId,
        'bank_name': bankName,
        'account_number': accountNumber,
        'ifsc_code': ifscCode,
        'branch_name': branchName,
      };
}
