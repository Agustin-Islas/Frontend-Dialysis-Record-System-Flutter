class RegisterDoctorRequest {
  final String email;
  final String name;
  final String surname;

  RegisterDoctorRequest({
    required this.email,
    required this.name,
    required this.surname,
  });

  Map<String, dynamic> toJson() => {
    'email': email,
    'name': name,
    'surname': surname,
  };
}
