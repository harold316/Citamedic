import 'package:url_launcher/url_launcher.dart';

import '../models/doctor.dart';

const supportWhatsAppNumber = '59173906744';

Future<bool> openSupportWhatsApp() {
  return _openWhatsApp(
    supportWhatsAppNumber,
    'Hola, necesito soporte técnico de CitaMedic.',
  );
}

Future<bool> openDoctorWhatsApp(
  Doctor doctor, {
  String message = 'Hola, vi tu perfil en CitaMedic y quiero agendar una cita.',
}) async {
  if (!doctor.hasWhatsApp) {
    return false;
  }
  return _openWhatsApp(doctor.whatsappNumber, message);
}

Future<bool> _openWhatsApp(String number, String message) {
  final uri = Uri.parse(
    'https://wa.me/$number?text=${Uri.encodeComponent(message)}',
  );
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
