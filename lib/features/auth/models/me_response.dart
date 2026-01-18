import 'package:flutter/widgets.dart';

class MeResponse { //TODO: modelo para patient, crear uno nuevo para doctor si es necesario
  final String? id;
  final String? email;
  final String? name;
  final String? surname;
  final String role;
  final String? dni;
  final String? dateOfBirth;
  final String? address;
  final String? number;
  final String? doctorName;
  final String? doctorId;

  MeResponse({
    required this.role,
    this.id,
    this.email,
    this.name,
    this.surname,
    this.dni,
    this.dateOfBirth,
    this.address,
    this.number,
    this.doctorName,
    this.doctorId,
  });

  factory MeResponse.fromJson(Map<String, dynamic> json) {
    return MeResponse(
      role: (json['role'] ?? '').toString(),
      id: json['id']?.toString(),
      email: json['email']?.toString(),
      name: json['name']?.toString(),
      surname: json['surname']?.toString(),
      dni: json['dni']?.toString(),
      dateOfBirth: json['dateOfBirth']?.toString(),
      address: json['address']?.toString(),
      number: json['number']?.toString(),
      doctorName: json['doctorName']?.toString(),
      doctorId: json['doctorId']?.toString(),
    );
  }
}