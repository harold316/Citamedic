import 'package:url_launcher/url_launcher.dart';

import '../models/doctor.dart';

Future<bool> openDoctorWhatsApp(
  Doctor doctor, {
  String message = 'Hola, vi tu perfil en CitaMedic y quiero agendar una cita.',
}) async {
  if (!doctor.hasWhatsApp) {
    return false;
  }
  final uri = Uri.parse(
    'https://wa.me/${doctor.whatsappNumber}?text=${Uri.encodeComponent(message)}',
  );
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
