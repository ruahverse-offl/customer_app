class LoginRequest {
  final String email;
  final String password;
  const LoginRequest({required this.email, required this.password});
  Map<String, dynamic> toJson() => {'email': email, 'password': password};
}

class RegisterRequest {
  final String fullName;
  final String email;
  final String password;
  final String mobileNumber;
  const RegisterRequest({
    required this.fullName,
    required this.email,
    required this.password,
    required this.mobileNumber,
  });
  Map<String, dynamic> toJson() => {
    'full_name': fullName,
    'email': email,
    'password': password,
    'mobile_number': mobileNumber,
  };
}

class AuthUser {
  final String id;
  final String email;
  final String fullName;
  final String? mobileNumber;
  final String roleCode;

  const AuthUser({
    required this.id,
    required this.email,
    required this.fullName,
    this.mobileNumber,
    required this.roleCode,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
    id: json['id']?.toString() ?? '',
    email: json['email']?.toString() ?? '',
    fullName: (json['full_name'] ?? json['fullName'])?.toString() ?? '',
    mobileNumber: (json['mobile_number'] ?? json['mobileNumber'])?.toString(),
    roleCode: (json['role_code'] ?? json['roleCode'])?.toString() ?? 'CUSTOMER',
  );

  AuthUser copyWith({String? fullName, String? mobileNumber}) => AuthUser(
    id: id,
    email: email,
    fullName: fullName ?? this.fullName,
    mobileNumber: mobileNumber ?? this.mobileNumber,
    roleCode: roleCode,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'full_name': fullName,
    'mobile_number': mobileNumber,
    'role_code': roleCode,
  };
}
