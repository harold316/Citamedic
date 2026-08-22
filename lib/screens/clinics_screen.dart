import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/clinic.dart';
import '../providers/clinics_provider.dart';
import '../providers/doctors_provider.dart';
import '../providers/session_provider.dart';
import '../theme/app_theme.dart';
import '../utils/maps.dart';
import '../widgets/clinic_photo_gallery.dart';
import '../widgets/doctor_result_card.dart';
import '../widgets/network_photo.dart';
import '../widgets/notifications_bell_button.dart';
import '../widgets/service_list_tile.dart';
import 'doctor_profile_screen.dart';

class ClinicsScreen extends StatelessWidget {
  const ClinicsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final location = context.watch<SessionProvider>().location;
    final clinics = context.watch<ClinicsProvider>().nearby(location);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Clínicas'),
        actions: const [NotificationsBellButton()],
      ),
      body: clinics.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No hay clínicas en tu ubicación.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        itemCount: clinics.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final clinic = clinics[index];
          return _ClinicCard(
            clinic: clinic,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ClinicDetailScreen(clinic: clinic),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class ClinicDetailScreen extends StatelessWidget {
  const ClinicDetailScreen({super.key, required this.clinic});

  final Clinic clinic;

  @override
  Widget build(BuildContext context) {
    final doctors = context.watch<DoctorsProvider>().byHospital(clinic.name);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(clinic.name),
        actions: const [NotificationsBellButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          if (clinic.gallery.isNotEmpty) ...[
            ClinicPhotoGallery(urls: clinic.gallery),
            ClinicPhotoDots(count: clinic.gallery.length),
          ] else
            SizedBox(
              height: 180,
              child: NetworkPhoto(
                url: clinic.photoUrl,
                viewable: true,
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          const SizedBox(height: 16),
          Text(
            clinic.address,
            style: TextStyle(color: AppColors.of(context).muted),
          ),
          Text(
            '${clinic.city}, ${clinic.region}',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.of(context).text,
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () async {
              final opened = await openClinicMap(clinic);
              if (!opened && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No se pudo abrir el mapa.')),
                );
              }
            },
            icon: const Icon(
              Icons.directions_outlined,
              color: AppColors.location,
            ),
            label: Text(
              clinic.hasGpsLocation
                  ? 'Cómo llegar (GPS)'
                  : 'Ver ubicación en el mapa',
            ),
          ),
          if (clinic.phone.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              clinic.phone,
              style: TextStyle(color: AppColors.of(context).text),
            ),
          ],
          if (clinic.about.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              clinic.about,
              style: TextStyle(
                color: AppColors.of(context).text,
                height: 1.4,
              ),
            ),
          ],
          if (clinic.services.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text(
              'Servicios',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 12),
            ...clinic.services.map(
              (service) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ServiceListTile(
                  service: service,
                  onTap: () {},
                  trailingIcon: Icons.schedule,
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          const Text(
            'Profesionales',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 12),
          if (doctors.isEmpty)
            const Text('No hay profesionales asignados en esta clínica.')
          else
            ...doctors.map((doctor) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DoctorResultCard(
                  doctor: doctor,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DoctorProfileScreen(doctorId: doctor.id),
                      ),
                    );
                  },
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _ClinicCard extends StatelessWidget {
  const _ClinicCard({required this.clinic, required this.onTap});

  final Clinic clinic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.of(context).surface,
      elevation: 2,
      shadowColor: Colors.black12,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              SizedBox(
                width: 78,
                height: 78,
                child: NetworkPhoto(
                  url: clinic.photoUrl,
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      clinic.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.of(context).text,
                      ),
                    ),
                    Text(
                      clinic.city,
                      style: TextStyle(
                        color: AppColors.of(context).muted,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star, color: AppColors.star, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          clinic.rating.toStringAsFixed(1),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}
