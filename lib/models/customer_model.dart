class Customer {
  final int id;
  final String fullName;
  final String mobileNumber;
  final String? email;
  final String? state;
  final String? city;
  final String? address;
  final DateTime? dob;
  final DateTime? anniversaryDate;
  final String? gender;
  final String? height;
  final double? weightKg;
  final String? education;
  final String? maritalStatus;
  final String? businessJobType;
  final String? businessJobName;
  final String? dutyType;
  final double? annualIncome;
  final String? panNo;
  final String? gstNo;
  
  final String? generatedUsername;
  final String? generatedPassword;
  final bool isActive;

  Customer({
    required this.id,
    required this.fullName,
    required this.mobileNumber,
    this.email,
    this.state,
    this.city,
    this.address,
    this.dob,
    this.anniversaryDate,
    this.gender,
    this.height,
    this.weightKg,
    this.education,
    this.maritalStatus,
    this.businessJobType,
    this.businessJobName,
    this.dutyType,
    this.annualIncome,
    this.panNo,
    this.gstNo,
    this.generatedUsername,
    this.generatedPassword,
    this.isActive = true,
  });

  Customer copyWith({bool? isActive}) => Customer(
        id: id,
        fullName: fullName,
        mobileNumber: mobileNumber,
        email: email,
        state: state,
        city: city,
        address: address,
        dob: dob,
        anniversaryDate: anniversaryDate,
        gender: gender,
        height: height,
        weightKg: weightKg,
        education: education,
        maritalStatus: maritalStatus,
        businessJobType: businessJobType,
        businessJobName: businessJobName,
        dutyType: dutyType,
        annualIncome: annualIncome,
        panNo: panNo,
        gstNo: gstNo,
        generatedUsername: generatedUsername,
        generatedPassword: generatedPassword,
        isActive: isActive ?? this.isActive,
      );

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'],
      fullName: json['full_name'] ?? '',
      mobileNumber: json['mobile_number'] ?? '',
      email: json['email'],
      state: json['state'],
      city: json['city'],
      address: json['address'],
      dob: json['dob'] != null ? DateTime.tryParse(json['dob']) : null,
      anniversaryDate: json['anniversary_date'] != null ? DateTime.tryParse(json['anniversary_date']) : null,
      gender: json['gender'],
      height: json['height'],
      weightKg: json['weight_kg'] != null ? (json['weight_kg'] as num).toDouble() : null,
      education: json['education'],
      maritalStatus: json['marital_status'],
      businessJobType: json['business_job_type'],
      businessJobName: json['business_job_name'],
      dutyType: json['duty_type'],
      annualIncome: json['annual_income'] != null ? (json['annual_income'] as num).toDouble() : null,
      panNo: json['pan_no'],
      gstNo: json['gst_no'],
      generatedUsername: json['generated_username'],
      generatedPassword: json['generated_password'],
      isActive: json['is_active'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'mobile_number': mobileNumber,
      if (email != null) 'email': email,
      'state': state ?? '',
      'city': city ?? '',
      'address': address ?? '',
      if (dob != null) 'dob': dob!.toIso8601String().split('T')[0],
      if (anniversaryDate != null) 'anniversary_date': anniversaryDate!.toIso8601String().split('T')[0],
      if (gender != null) 'gender': gender,
      if (height != null) 'height': height,
      if (weightKg != null) 'weight_kg': weightKg,
      if (education != null) 'education': education,
      if (maritalStatus != null) 'marital_status': maritalStatus,
      if (businessJobType != null) 'business_job_type': businessJobType,
      if (businessJobName != null) 'business_job_name': businessJobName,
      if (dutyType != null) 'duty_type': dutyType,
      if (annualIncome != null) 'annual_income': annualIncome,
      if (panNo != null) 'pan_no': panNo,
      if (gstNo != null) 'gst_no': gstNo,
      'is_active': isActive ? 1 : 0,
    };
  }
}
