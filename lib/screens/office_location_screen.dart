import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/doctors_provider.dart';
import '../theme/app_theme.dart';
import '../utils/maps.dart';
import '../widgets/primary_pill_button.dart';

class OfficeLocationScreen extends StatefulWidget {
  const OfficeLocationScreen({super.key, required this.doctorId});

  final String doctorId;

  @override
  State<OfficeLocationScreen> createState() => _OfficeLocationScreenState();
}

class _OfficeLocationScreenState extends State<OfficeLocationScreen> {
  late final TextEditingController _addressController;
  late final TextEditingController _cityController;
  double? _latitude;
  double? _longitude;
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    final doctor = context.read<DoctorsProvider>().byId(widget.doctorId);
    _addressController = TextEditingController(
      text: doctor.officeAddress ?? '${doctor.hospital}, ${doctor.city}',
    );
    _cityController = TextEditingController(text: doctor.city);
    _latitude = doctor.latitude;
    _longitude = doctor.longitude;
  }

  @override
  void dispose() {
    _addressController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final canEdit = auth.isDoctor && auth.uid == widget.doctorId;
    if (!canEdit) {
      return Scaffold(
        appBar: AppBar(title: const Text('Consultorio')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Los pacientes solo pueden ver la información. Solo el médico puede cambiar su consultorio.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    final doctor = context.watch<DoctorsProvider>().byId(widget.doctorId);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Ubicación del consultorio'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          Text(
            doctor.name,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: AppColors.of(context).text,
            ),
          ),
          Text(
            doctor.specialty,
            style: TextStyle(color: AppColors.of(context).muted),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _addressController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Dirección del consultorio',
              hintText: 'Calle, número, referencia',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _cityController,
            decoration: const InputDecoration(labelText: 'Ciudad'),
          ),
          const SizedBox(height: 16),
          if (_latitude != null && _longitude != null)
            Text(
              'Coordenadas: ${_latitude!.toStringAsFixed(5)}, ${_longitude!.toStringAsFixed(5)}',
              style: TextStyle(color: AppColors.of(context).muted, fontSize: 12),
            ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _locating ? null : _useCurrentLocation,
            icon: _locating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location, color: AppColors.location),
            label: Text(
              _locating ? 'Obteniendo ubicación...' : 'Usar mi ubicación actual',
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () async {
              final doctor = context.read<DoctorsProvider>().byId(widget.doctorId);
              final opened = await openDoctorOfficeMap(
                doctor.copyWith(
                  officeAddress: _addressController.text.trim(),
                  latitude: _latitude,
                  longitude: _longitude,
                ),
              );
              if (!opened && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No se pudo abrir el mapa.')),
                );
              }
            },
            icon: const Icon(Icons.map_outlined, color: AppColors.location),
            label: const Text('Ver en el mapa'),
          ),
          const SizedBox(height: 28),
          PrimaryPillButton(label: 'Guardar ubicación', onPressed: _save),
        ],
      ),
    );
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _locating = true);
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        _showMessage('Activa el GPS para registrar la ubicación.');
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _showMessage('Necesitamos permiso de ubicación para el consultorio.');
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        if (_addressController.text.trim().isEmpty) {
          _addressController.text =
              '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';
        }
      });
    } catch (_) {
      _showMessage('No se pudo obtener la ubicación actual.');
    } finally {
      if (mounted) {
        setState(() => _locating = false);
      }
    }
  }

  Future<void> _save() async {
    final address = _addressController.text.trim();
    if (address.isEmpty) {
      _showMessage('Escribe la dirección del consultorio.');
      return;
    }

    try {
      await context.read<DoctorsProvider>().updateOfficeLocation(
        doctorId: widget.doctorId,
        officeAddress: address,
        city: _cityController.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage(
        context.read<AuthProvider>().messageFor(error),
      );
      return;
    }
    if (!mounted) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('Ubicación del consultorio guardada.')),
    );
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}
