class UserModel {
  final int id;
  final String name;
  final String email;
  final String role;
  final bool isEmailVerified;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.isEmailVerified = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final userMap = json['user'] is Map<String, dynamic>
        ? json['user'] as Map<String, dynamic>
        : json;

    return UserModel(
      id: userMap['id'] is int
          ? userMap['id']
          : int.tryParse(userMap['id']?.toString() ?? '1') ?? 1,
      name: userMap['name'] ??
          userMap['full_name'] ??
          userMap['email']?.toString().split('@').first ??
          'User',
      email: userMap['email']?.toString() ?? '',
      role: (userMap['role'] ?? 'student').toString().toLowerCase(),
      isEmailVerified: userMap['is_email_verified'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'is_email_verified': isEmailVerified,
    };
  }
}

class AuthResponseModel {
  final String accessToken;
  final String? refreshToken;
  final String tokenType;
  final UserModel user;

  AuthResponseModel({
    required this.accessToken,
    this.refreshToken,
    this.tokenType = 'bearer',
    required this.user,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    final token = json['access_token']?.toString() ??
        json['token']?.toString() ??
        'ssc_token_${DateTime.now().millisecondsSinceEpoch}';
    final refreshToken = json['refresh_token']?.toString() ??
        'ssc_refresh_token_${DateTime.now().millisecondsSinceEpoch}';
    final tokenType = json['token_type']?.toString() ?? 'bearer';
    final userModel = UserModel.fromJson(json);

    return AuthResponseModel(
      accessToken: token,
      refreshToken: refreshToken,
      tokenType: tokenType,
      user: userModel,
    );
  }
}
