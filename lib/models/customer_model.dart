class Customer {
  final int id;
  final String fullName;
  final String mobileNumber;
  final String? email;
  final String? state;
  final String? city;
  final String? address;
  final String? gender;
  final String? maritalStatus;
  final String? jobType;
  final String? panNo;
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
    this.gender,
    this.maritalStatus,
    this.jobType,
    this.panNo,
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
        gender: gender,
        maritalStatus: maritalStatus,
        jobType: jobType,
        panNo: panNo,
        generatedUsername: generatedUsername,
        generatedPassword: generatedPassword,
        isActive: isActive ?? this.isActive,
      );

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'],
      fullName: json['full_name'],
      mobileNumber: json['mobile_number'],
      email: json['email'],
      state: json['state'],
      city: json['city'],
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
      'email': email,
      'state': state,
      'city': city,
      'address': address,
      'gender': gender,
      'marital_status': maritalStatus,
      'job_type': jobType,
      'pan_no': panNo,
      'is_active': isActive ? 1 : 0,
    };
  }
}
