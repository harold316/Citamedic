import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/mock_data.dart';
import '../providers/auth_provider.dart';
import '../providers/doctors_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/guest_guard.dart';
import '../utils/whatsapp.dart';
import '../widgets/network_photo.dart';
import '../widgets/office_location_card.dart';
import '../widgets/primary_pill_button.dart';
import '../widgets/service_list_tile.dart';
import '../widgets/stat_chip.dart';
import 'appointment_summary_screen.dart';
import 'office_location_screen.dart';

class DoctorProfileScreen extends StatelessWidget {
  const DoctorProfileScreen({
    super.key,
    required this.doctorId,
    this.highlightedServiceId,
  });

  final String doctorId;
  final String? highlightedServiceId;

  @override
  Widget build(BuildContext context) {
    final doctorsProvider = context.watch<DoctorsProvider>();
    final auth = context.watch<AuthProvider>();
    final doctor = doctorsProvider.byId(doctorId);
    final isFavorite = doctorsProvider.isFavorite(doctor.id);
    final colors = AppColors.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: SizedBox(
              height: 360,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: NetworkPhoto(
                      url: doctor.photoUrl,
                      viewable: true,
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(32),
                      ),
                    ),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          CircleIconButton(
                            icon: Icons.arrow_back_ios_new,
                            onPressed: () => Navigator.pop(context),
                          ),
                          CircleIconButton(
                            icon: isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            iconColor: isFavorite
                                ? AppColors.danger
                                : AppColors.primary,
                            onPressed: () =>
                                doctorsProvider.toggleFavorite(doctor.id),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    bottom: 20,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star, color: AppColors.star, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            doctor.rating.toStringAsFixed(1),
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            sliver: SliverList.list(
              children: [
                Text(
                  doctor.name,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: colors.text,
                  ),
                ),
                Text(
                  doctor.credentials,
                  style: TextStyle(
                    color: colors.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  doctor.specialty == defaultSpecialty
                      ? doctor.specialty
                      : '${doctor.specialty} especialista',
                  style: const TextStyle(color: AppColors.primary),
                ),
                const SizedBox(height: 16),
                Text(
                  'Horario de atención',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: colors.text,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  doctor.workingHours,
                  style: TextStyle(color: colors.muted),
                ),
                if (doctor.hasWhatsApp) ...[
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => openDoctorWhatsApp(doctor),
                    icon: const Icon(Icons.chat, color: AppColors.whatsapp),
                    label: Text('WhatsApp ${doctor.phone}'),
                  ),
                ],
                const SizedBox(height: 18),
                OfficeLocationCard(
                  doctor: doctor,
                  onEdit: auth.isDoctor && auth.uid == doctor.id
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  OfficeLocationScreen(doctorId: doctor.id),
                            ),
                          );
                        }
                      : null,
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      StatChip(
                        icon: Icons.workspace_premium_outlined,
                        value: '${doctor.yearsExperience} años',
                        label: 'Experiencia',
                        color: const Color(0xFFE8A838),
                      ),
                      StatChip(
                        icon: Icons.groups_outlined,
                        value: formatCompact(doctor.patientsCount),
                        label: 'Pacientes',
                        color: AppColors.primary,
                      ),
                      StatChip(
                        icon: Icons.reviews_outlined,
                        value: formatCompact(doctor.reviewCount),
                        label: 'Reseñas',
                        color: AppColors.accent,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Acerca del doctor',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: colors.text,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  doctor.about,
                  style: TextStyle(color: colors.muted, height: 1.45),
                ),
                const SizedBox(height: 22),
                Text(
                  'Servicios',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: colors.text,
                  ),
                ),
                if (auth.isGuest) ...[
                  const SizedBox(height: 8),
                  Text(
                    'En modo invitado puedes ver los servicios, pero no agendar.',
                    style: TextStyle(color: colors.muted, height: 1.35),
                  ),
                ],
                const SizedBox(height: 12),
                ...doctor.services.map((service) {
                  final highlighted =
                      service.id == highlightedServiceId ||
                      (highlightedServiceId == null &&
                          service.id == doctor.services.first.id);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ServiceListTile(
                      service: service,
                      highlighted: highlighted,
                      trailingIcon: auth.isGuest
                          ? Icons.lock_outline
                          : Icons.north_east,
                      onTap: () {
                        if (blockGuestBooking(context)) {
                          return;
                        }
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AppointmentSummaryScreen(
                              doctorId: doctor.id,
                              serviceId: service.id,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
