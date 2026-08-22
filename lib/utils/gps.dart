import 'package:geolocator/geolocator.dart';

class GpsFix {
  const GpsFix(this.latitude, this.longitude);

  final double latitude;
  final double longitude;
}

Future<GpsFix> readCurrentGps() async {
  final enabled = await Geolocator.isLocationServiceEnabled();
  if (!enabled) {
    throw StateError('Activa el GPS para registrar la ubicación.');
  }

  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.denied ||
      permission == LocationPermission.deniedForever) {
    throw StateError('Necesitamos permiso de ubicación para compartir el GPS.');
  }

  final position = await Geolocator.getCurrentPosition();
  return GpsFix(position.latitude, position.longitude);
}
