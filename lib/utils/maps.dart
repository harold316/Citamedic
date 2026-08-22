import 'package:url_launcher/url_launcher.dart';

import '../models/clinic.dart';
import '../models/doctor.dart';

Future<bool> openDoctorOfficeMap(Doctor doctor) async {
  final Uri uri;
  if (doctor.latitude != null && doctor.longitude != null) {
    uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${doctor.latitude},${doctor.longitude}',
    );
  } else {
    uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(doctor.locationLabel)}',
    );
  }
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}

Future<bool> openClinicMap(Clinic clinic) async {
  final Uri uri;
  if (clinic.latitude != null && clinic.longitude != null) {
    uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${clinic.latitude},${clinic.longitude}',
    );
  } else {
    uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(clinic.locationLabel)}',
    );
  }
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
