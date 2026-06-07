class RegisterDoctorRequest {
  final String email;
  final String password;
  final String name;
  final String surname;

  RegisterDoctorRequest({
    required this.email,
    required this.password,
    required this.name,
    required this.surname,
  });

  Map<String, dynamic> toJson() => {
    'email': email,
    'password': password,
    'name': name,
    'surname': surname,
  };
}
