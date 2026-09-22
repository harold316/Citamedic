import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/appointment.dart';
import '../providers/appointments_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/doctors_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/maps.dart';
import '../utils/whatsapp.dart';
import '../widgets/doctor_mini_card.dart';

Future<void> openAppointmentDetail(
  BuildContext context,
  Appointment appointment,
) {
  return Navigator.of(context, rootNavigator: true).push<void>(
    MaterialPageRoute(
      builder: (_) => AppointmentDetailScreen(appointment: appointment),
    ),
  );
}

Future<void> deleteAppointmentWithConfirm(
  BuildContext context, {
  required Appointment appointment,
  bool popOnSuccess = false,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Eliminar cita'),
        content: const Text(
          '¿Quieres eliminar esta cita? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Eliminar'),
          ),
        ],
      );
    },
  );
  if (confirmed != true || !context.mounted) {
    return;
  }

  final auth = context.read<AuthProvider>();
  try {
    await context.read<AppointmentsProvider>().remove(appointment.id);
  } catch (error) {
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(auth.messageFor(error))),
    );
    return;
  }
  if (!context.mounted) {
    return;
  }
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Cita eliminada.')),
  );
  if (popOnSuccess) {
    Navigator.pop(context);
  }
}

Future<void> acceptAppointmentWithConfirm(
  BuildContext context, {
  required Appointment appointment,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('Aceptar cita'),
        content: Text(
          '¿Confirmas la cita de ${appointment.patientName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Aceptar'),
          ),
        ],
      );
    },
  );
  if (confirmed != true || !context.mounted) {
    return;
  }
  await _runAppointmentAction(
    context,
    action: () => context.read<AppointmentsProvider>().accept(appointment.id),
    success: 'Cita aceptada.',
  );
}

Future<void> rescheduleAppointment(
  BuildContext context, {
  required Appointment appointment,
}) async {
  final now = DateTime.now();
  final initial = appointment.dateTime.isBefore(now)
      ? now.add(const Duration(hours: 1))
      : appointment.dateTime;
  final date = await showDatePicker(
    context: context,
    initialDate: DateTime(initial.year, initial.month, initial.day),
    firstDate: DateTime(now.year, now.month, now.day),
    lastDate: now.add(const Duration(days: 120)),
  );
  if (date == null || !context.mounted) {
    return;
  }
  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(initial),
  );
  if (time == null || !context.mounted) {
    return;
  }
  final next = DateTime(
    date.year,
    date.month,
    date.day,
    time.hour,
    time.minute,
  );
  await _runAppointmentAction(
    context,
    action: () => context.read<AppointmentsProvider>().reschedule(
      appointment.id,
      next,
    ),
    success: 'Horario actualizado.',
  );
}

Future<void> _runAppointmentAction(
  BuildContext context, {
  required Future<void> Function() action,
  required String success,
}) async {
  final auth = context.read<AuthProvider>();
  try {
    await action();
  } catch (error) {
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(auth.messageFor(error))),
    );
    return;
  }
  if (!context.mounted) {
    return;
  }
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success)));
}

class AppointmentDetailScreen extends StatelessWidget {
  const AppointmentDetailScreen({super.key, required this.appointment});

  final Appointment appointment;

  @override
  Widget build(BuildContext context) {
    final current =
        context.watch<AppointmentsProvider>().byId(appointment.id) ??
        appointment;

    final auth = context.watch<AuthProvider>();
    final doctor = context.watch<DoctorsProvider>().findById(current.doctorId);
    final dateLabel = DateFormat("EEEE d 'de' MMMM, HH:mm", 'es').format(
      current.dateTime,
    );
    final viewingAsDoctor = auth.isDoctor;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Detalle de la cita'),
        actions: [
          IconButton(
            tooltip: 'Eliminar cita',
            onPressed: () => deleteAppointmentWithConfirm(
              context,
              appointment: current,
              popOnSuccess: true,
            ),
            icon: const Icon(Icons.delete_outline, color: AppColors.danger),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          if (doctor != null && !viewingAsDoctor) ...[
            DoctorMiniCard(doctor: doctor),
            const SizedBox(height: 22),
          ],
          const _SectionTitle('Datos de la cita'),
          if (viewingAsDoctor) ...[
            _InfoRow(label: 'Paciente', value: current.patientName),
            if (current.patientEmail.isNotEmpty)
              _InfoRow(label: 'Correo', value: current.patientEmail),
          ] else if (doctor != null) ...[
            _InfoRow(label: 'Médico', value: doctor.name),
            _InfoRow(label: 'Especialidad', value: doctor.specialty),
            _InfoRow(label: 'Hospital', value: doctor.hospital),
            _InfoRow(label: 'Ciudad', value: doctor.city),
            if (doctor.hasWhatsApp)
              _InfoRow(
                label: 'WhatsApp',
                value: doctor.phone,
                onTap: () => openDoctorWhatsApp(doctor),
              ),
            if (doctor.hasOfficeLocation)
              _InfoRow(
                label: 'Consultorio',
                value: doctor.locationLabel,
                onTap: () => openDoctorOfficeMap(doctor),
              ),
          ],
          _InfoRow(
            label: 'Servicio',
            value: current.serviceName.isNotEmpty
                ? current.serviceName
                : 'Consulta',
          ),
          _InfoRow(label: 'Fecha', value: dateLabel),
          _InfoRow(
            label: 'Duración',
            value: '${current.durationMinutes} min',
          ),
          _InfoRow(label: 'Precio', value: formatPrice(current.price)),
          _InfoRow(label: 'Pago', value: current.paymentMethod),
          _InfoRow(label: 'Estado', value: current.statusLabel),
          if (current.hasPatientMessage) ...[
            const SizedBox(height: 18),
            const _SectionTitle('Mensaje del paciente'),
            Text(
              current.patientMessage,
              style: TextStyle(
                color: AppColors.of(context).text,
                height: 1.4,
              ),
            ),
          ],
          if (viewingAsDoctor) ...[
            const SizedBox(height: 24),
            if (current.isPending)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => acceptAppointmentWithConfirm(
                    context,
                    appointment: current,
                  ),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Aceptar cita'),
                ),
              ),
            if (current.isPending) const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => rescheduleAppointment(
                  context,
                  appointment: current,
                ),
                icon: const Icon(Icons.schedule),
                label: const Text('Cambiar horario'),
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => deleteAppointmentWithConfirm(
                context,
                appointment: current,
                popOnSuccess: true,
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
              ),
              icon: const Icon(Icons.delete_outline),
              label: const Text('Eliminar cita'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 16,
          color: AppColors.of(context).text,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, this.onTap});

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Text(label, style: TextStyle(color: AppColors.of(context).muted)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: AppColors.of(context).text,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (onTap != null)
              const Padding(
                padding: EdgeInsets.only(left: 6),
                child: Icon(
                  Icons.chevron_right,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
