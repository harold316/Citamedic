import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/clinic.dart';
import '../models/doctor_review_status.dart';
import '../providers/auth_provider.dart';
import '../providers/clinics_provider.dart';
import '../theme/app_theme.dart';
import '../utils/maps.dart';
import '../widgets/clinic_photo_gallery.dart';
import '../widgets/network_photo.dart';
import '../widgets/primary_pill_button.dart';
import '../widgets/service_list_tile.dart';

class AdminClinicReviewScreen extends StatefulWidget {
  const AdminClinicReviewScreen({super.key, required this.clinicId});

  final String clinicId;

  @override
  State<AdminClinicReviewScreen> createState() =>
      _AdminClinicReviewScreenState();
}

class _AdminClinicReviewScreenState extends State<AdminClinicReviewScreen> {
  bool _working = false;
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final clinics = context.watch<ClinicsProvider>();
    final matches = clinics.registeredClinics.where(
      (item) => item.id == widget.clinicId,
    );
    final clinic = matches.isEmpty ? null : matches.first;

    if (clinic == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Revisión')),
        body: const Center(child: Text('Esta clínica ya no está disponible.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Verificar clínica')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          if (clinic.gallery.isNotEmpty) ...[
            ClinicPhotoGallery(urls: clinic.gallery),
            ClinicPhotoDots(count: clinic.gallery.length),
          ] else
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: SizedBox(
                height: 220,
                child: NetworkPhoto(url: clinic.photoUrl, viewable: true),
              ),
            ),
          const SizedBox(height: 16),
          Text(
            clinic.name,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: colors.text,
            ),
          ),
          Text(clinic.address, style: TextStyle(color: colors.muted)),
          Text(
            '${clinic.city}, ${clinic.region}',
            style: TextStyle(color: colors.muted),
          ),
          if (clinic.hasGpsLocation) ...[
            const SizedBox(height: 6),
            Text(
              'GPS: ${clinic.latitude!.toStringAsFixed(5)}, ${clinic.longitude!.toStringAsFixed(5)}',
              style: TextStyle(color: colors.muted, fontSize: 12),
            ),
          ],
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => openClinicMap(clinic),
            icon: const Icon(
              Icons.directions_outlined,
              color: AppColors.location,
            ),
            label: const Text('Ver en el mapa'),
          ),
          if (clinic.phone.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(clinic.phone, style: TextStyle(color: colors.text)),
          ],
          if (clinic.about.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(clinic.about, style: TextStyle(color: colors.text, height: 1.4)),
          ],
          if (clinic.services.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Servicios',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: colors.text,
              ),
            ),
            const SizedBox(height: 8),
            ...clinic.services.map(
              (service) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: ServiceListTile(
                  service: service,
                  onTap: () {},
                  trailingIcon: Icons.schedule,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            clinic.reviewStatus.label,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: clinic.reviewStatus == DoctorReviewStatus.approved
                  ? AppColors.primary
                  : clinic.reviewStatus == DoctorReviewStatus.rejected
                  ? AppColors.danger
                  : const Color(0xFFE8A838),
            ),
          ),
          const SizedBox(height: 24),
          if (clinic.reviewStatus != DoctorReviewStatus.approved)
            PrimaryPillButton(
              label: _working ? 'Espera...' : 'Publicar clínica',
              onPressed: _working ? null : () => _approve(clinic),
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _reasonController,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Motivo si la rechazas',
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _working ? null : () => _reject(clinic),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );
  }

  Future<void> _approve(Clinic clinic) async {
    setState(() => _working = true);
    try {
      await context.read<ClinicsProvider>().approveClinic(
        clinic,
        adminEmail: context.read<AuthProvider>().email,
      );
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.read<AuthProvider>().messageFor(error))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _working = false);
      }
    }
  }

  Future<void> _reject(Clinic clinic) async {
    setState(() => _working = true);
    try {
      await context.read<ClinicsProvider>().rejectClinic(
        clinic,
        reason: _reasonController.text,
        adminEmail: context.read<AuthProvider>().email,
      );
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.read<AuthProvider>().messageFor(error))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _working = false);
      }
    }
  }
}
