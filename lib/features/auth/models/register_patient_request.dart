class RegisterPatientRequest {
  final String email;
  final String password;
  final String name;
  final String surname;
  final int dni;
  final String dateOfBirth; // YYYY-MM-DD
  final String address;
  final int number;

  RegisterPatientRequest({
    required this.email,
    required this.password,
    required this.name,
    required this.surname,
    required this.dni,
    required this.dateOfBirth,
    required this.address,
    required this.number,
  });

  Map<String, dynamic> toJson() => {
        "email": email,
        "password": password,
        "name": name,
        "surname": surname,
        "dni": dni,
        "dateOfBirth": dateOfBirth,
        "address": address,
        "number": number,
      };
}
