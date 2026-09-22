import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/appointment.dart';
import '../providers/appointments_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/doctors_provider.dart';
import '../providers/session_provider.dart';
import '../providers/shell_tab_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/guest_guard.dart';
import '../utils/maps.dart';
import '../utils/whatsapp.dart';
import '../widgets/doctor_mini_card.dart';
import '../widgets/primary_pill_button.dart';

class AppointmentSummaryScreen extends StatefulWidget {
  const AppointmentSummaryScreen({
    super.key,
    required this.doctorId,
    required this.serviceId,
  });

  final String doctorId;
  final String serviceId;

  @override
  State<AppointmentSummaryScreen> createState() =>
      _AppointmentSummaryScreenState();
}

class _AppointmentSummaryScreenState extends State<AppointmentSummaryScreen> {
  late DateTime _date;
  late TimeOfDay _time;
  final _message = TextEditingController();

  @override
  void initState() {
    super.initState();
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    _date = DateTime(tomorrow.year, tomorrow.month, tomorrow.day);
    _time = const TimeOfDay(hour: 10, minute: 0);
  }

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  DateTime get _dateTime => DateTime(
    _date.year,
    _date.month,
    _date.day,
    _time.hour,
    _time.minute,
  );

  @override
  Widget build(BuildContext context) {
    final doctor = context.watch<DoctorsProvider>().byId(widget.doctorId);
    final service = doctor.serviceById(widget.serviceId);
    final dateLabel = DateFormat.yMMMd().format(_date);
    final timeLabel = _time.format(context);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Resumen de la cita'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
        children: [
          DoctorMiniCard(doctor: doctor),
          const SizedBox(height: 22),
          const _SectionTitle('Datos del centro'),
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
          _InfoRow(label: 'Servicio', value: service.name),
          const SizedBox(height: 18),
          const _SectionTitle('Confirmar cita'),
          _InfoRow(
            label: 'Fecha',
            value: dateLabel,
            onTap: _pickDate,
          ),
          _InfoRow(label: 'Hora', value: timeLabel, onTap: _pickTime),
          _InfoRow(label: 'Duración', value: '${service.durationMinutes} min'),
          _InfoRow(label: 'Precio', value: formatPrice(service.price)),
          const _InfoRow(label: 'Pago', value: 'En clínica'),
          const SizedBox(height: 18),
          const _SectionTitle('Mensaje para el médico'),
          TextField(
            controller: _message,
            minLines: 3,
            maxLines: 5,
            maxLength: 240,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'Opcional. Motivo de la consulta, síntomas o un recado.',
            ),
          ),
          const SizedBox(height: 20),
          if (context.watch<AuthProvider>().isGuest)
            PrimaryPillButton(
              label: 'Inicia sesión para agendar',
              onPressed: () => blockGuestBooking(context),
            )
          else
            PrimaryPillButton(
              label: 'Confirmar, agendaré',
              onPressed: () => _confirm(context),
            ),
          const SizedBox(height: 12),
          SecondaryPillButton(
            label: 'Cancelar',
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 120)),
    );
    if (selected != null) {
      setState(() => _date = selected);
    }
  }

  Future<void> _pickTime() async {
    final selected = await showTimePicker(context: context, initialTime: _time);
    if (selected != null) {
      setState(() => _time = selected);
    }
  }

  Future<void> _confirm(BuildContext context) async {
    final doctor = context.read<DoctorsProvider>().byId(widget.doctorId);
    final service = doctor.serviceById(widget.serviceId);
    final auth = context.read<AuthProvider>();
    final session = context.read<SessionProvider>();
    if (blockGuestBooking(context)) {
      return;
    }
    try {
      await context.read<AppointmentsProvider>().confirm(
        Appointment(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          doctorId: doctor.id,
          patientId: auth.uid,
          patientName: session.patient?.name.trim().isNotEmpty == true
              ? session.patient!.name.trim()
              : auth.displayName,
          patientEmail: auth.email,
          serviceId: service.id,
          serviceName: service.name,
          dateTime: _dateTime,
          durationMinutes: service.durationMinutes,
          price: service.price,
          patientMessage: _message.text.trim(),
        ),
      );
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
    context.read<ShellTabProvider>().goTo(3);
    Navigator.of(context).popUntil((route) => route.isFirst);
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
              Padding(
                padding: const EdgeInsets.only(left: 6),
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
