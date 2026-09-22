import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/appointments_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/doctors_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/appointment_card.dart';
import '../widgets/network_photo.dart';
import '../widgets/notifications_bell_button.dart';
import 'appointment_detail_screen.dart';

class AppointmentsScreen extends StatelessWidget {
  const AppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appointments = context.watch<AppointmentsProvider>().appointments;
    final doctors = context.watch<DoctorsProvider>();

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(
                      'Mis citas',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: AppColors.of(context).text,
                      ),
                    ),
                  ),
                ),
                const NotificationsBellButton(),
              ],
            ),
          ),
          Expanded(
            child: appointments.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.event_available_outlined,
                            size: 48,
                            color: AppColors.primary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            context.watch<AuthProvider>().isGuest
                                ? 'En modo invitado no puedes agendar citas. Inicia sesión para reservar y ver tu historial.'
                                : 'Aún no tienes citas confirmadas.',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    itemCount: appointments.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final appointment = appointments[index];
                      final doctor = doctors.findById(appointment.doctorId);
                      final serviceName = appointment.serviceName.isNotEmpty
                          ? appointment.serviceName
                          : 'Consulta';

                      return AppointmentCard(
                        appointment: appointment,
                        title: doctor?.name ?? 'Médico',
                        subtitle: serviceName,
                        leading: doctor == null
                            ? null
                            : SizedBox(
                                width: 72,
                                height: 72,
                                child: NetworkPhoto(
                                  url: doctor.photoUrl,
                                  borderRadius: BorderRadius.circular(18),
                                ),
                              ),
                        onTap: () => openAppointmentDetail(
                          context,
                          appointment,
                        ),
                        onDelete: () => deleteAppointmentWithConfirm(
                          context,
                          appointment: appointment,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
