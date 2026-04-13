class UserModel {
  final int id;
  final String name;
  final String phoneNumber;
  final String? email;
  final int voltraPoints;
  final String role;
  final String kycStatus;
  final String walletBalance;
  final String? createdAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.phoneNumber,
    this.email,
    this.voltraPoints = 0,
    this.role = 'user',
    this.kycStatus = 'unverified',
    this.walletBalance = '0.00',
    this.createdAt,
  });

  bool get isSuperAdmin => role == 'superadmin';
  bool get isVerified => kycStatus == 'verified';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      name: json['name'] as String,
      phoneNumber: json['phone_number'] as String? ?? '',
      email: json['email'] as String?,
      voltraPoints: json['voltra_points'] as int? ?? 0,
      role: json['role'] as String? ?? 'user',
      kycStatus: json['kyc_status'] as String? ?? 'unverified',
      walletBalance: json['wallet_balance']?.toString() ?? '0.00',
      createdAt: json['created_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone_number': phoneNumber,
      'email': email,
      'voltra_points': voltraPoints,
      'role': role,
      'kyc_status': kycStatus,
      'wallet_balance': walletBalance,
      'created_at': createdAt,
    };
  }

  UserModel copyWith({
    String? name,
    String? email,
    int? voltraPoints,
    String? walletBalance,
    String? kycStatus,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      phoneNumber: phoneNumber,
      email: email ?? this.email,
      voltraPoints: voltraPoints ?? this.voltraPoints,
      role: role,
      kycStatus: kycStatus ?? this.kycStatus,
      walletBalance: walletBalance ?? this.walletBalance,
      createdAt: createdAt,
    );
  }
}
