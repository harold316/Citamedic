import 'package:cloud_firestore/cloud_firestore.dart';

class Appointment {
  final String id;
  final String doctorId;
  final String patientId;
  final String patientName;
  final String patientEmail;
  final String serviceId;
  final String serviceName;
  final DateTime dateTime;
  final int durationMinutes;
  final double price;
  final String paymentMethod;

  const Appointment({
    required this.id,
    required this.doctorId,
    required this.serviceId,
    required this.dateTime,
    required this.durationMinutes,
    required this.price,
    this.patientId = '',
    this.patientName = '',
    this.patientEmail = '',
    this.serviceName = '',
    this.paymentMethod = 'En clínica',
  });

  Map<String, dynamic> toMap() {
    return {
      'doctorId': doctorId,
      'patientId': patientId,
      'patientName': patientName,
      'patientEmail': patientEmail,
      'serviceId': serviceId,
      'serviceName': serviceName,
      'dateTime': Timestamp.fromDate(dateTime),
      'durationMinutes': durationMinutes,
      'price': price,
      'paymentMethod': paymentMethod,
    };
  }

  factory Appointment.fromMap(String id, Map<String, dynamic> data) {
    return Appointment(
      id: id,
      doctorId: data['doctorId'] as String? ?? '',
      patientId: data['patientId'] as String? ?? '',
      patientName: (data['patientName'] as String?)?.trim().isNotEmpty == true
          ? data['patientName'] as String
          : 'Paciente',
      patientEmail: data['patientEmail'] as String? ?? '',
      serviceId: data['serviceId'] as String? ?? '',
      serviceName: (data['serviceName'] as String?)?.trim().isNotEmpty == true
          ? data['serviceName'] as String
          : 'Consulta',
      dateTime: _dateFrom(data['dateTime']),
      durationMinutes: (data['durationMinutes'] as num?)?.toInt() ?? 30,
      price: (data['price'] as num?)?.toDouble() ?? 0,
      paymentMethod: data['paymentMethod'] as String? ?? 'En clínica',
    );
  }

  static DateTime _dateFrom(Object? raw) {
    if (raw is Timestamp) {
      return raw.toDate();
    }
    if (raw is DateTime) {
      return raw;
    }
    if (raw is String) {
      return DateTime.tryParse(raw) ?? DateTime.now();
    }
    return DateTime.now();
  }
}
