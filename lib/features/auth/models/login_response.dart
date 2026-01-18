class LoginResponse {
  final String accessToken;
  final String refreshToken;
  final String tokenType;

  LoginResponse({required this.accessToken, required this.refreshToken, required this.tokenType});

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      accessToken: json['accessToken'],
      refreshToken: json['refreshToken'],
      tokenType: json['tokenType'],
    );
  }
}