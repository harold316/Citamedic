import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/doctor.dart';
import '../models/doctor_review_status.dart';
import '../providers/auth_provider.dart';
import '../providers/doctors_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';
import '../utils/whatsapp.dart';
import '../widgets/network_photo.dart';
import '../widgets/primary_pill_button.dart';

class AdminDoctorReviewScreen extends StatefulWidget {
  const AdminDoctorReviewScreen({super.key, required this.doctorId});

  final String doctorId;

  @override
  State<AdminDoctorReviewScreen> createState() =>
      _AdminDoctorReviewScreenState();
}

class _AdminDoctorReviewScreenState extends State<AdminDoctorReviewScreen> {
  bool _working = false;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final doctors = context.watch<DoctorsProvider>();
    final matches = doctors.registeredDoctors.where(
      (item) => item.id == widget.doctorId,
    );
    final doctor = matches.isEmpty ? null : matches.first;

    if (doctor == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Revisión')),
        body: const Center(child: Text('Este perfil ya no está disponible.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Verificar perfil')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: SizedBox(
              height: 220,
              child: NetworkPhoto(url: doctor.photoUrl, viewable: true),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            doctor.name,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: colors.text,
            ),
          ),
          Text(doctor.specialty, style: TextStyle(color: colors.muted)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _Badge(
                label: doctor.reviewStatus.label,
                color: doctor.reviewStatus == DoctorReviewStatus.approved
                    ? AppColors.primary
                    : doctor.reviewStatus == DoctorReviewStatus.rejected
                    ? AppColors.danger
                    : const Color(0xFFE8A838),
              ),
              _Badge(
                label: 'Completitud ${doctor.profileScore}%',
                color: colors.text,
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Checklist de verificación',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: colors.text,
            ),
          ),
          const SizedBox(height: 8),
          ...doctor.profileChecks.map(
            (item) => ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                item.ok ? Icons.check_circle : Icons.cancel_outlined,
                color: item.ok ? AppColors.primary : AppColors.danger,
              ),
              title: Text(item.label),
              subtitle: Text(item.ok ? 'Completo' : 'Falta o está incompleto'),
            ),
          ),
          const SizedBox(height: 8),
          _InfoCard(
            children: [
              _InfoLine(label: 'Credenciales', value: doctor.credentials),
              _InfoLine(label: 'Clínica', value: doctor.hospital),
              _InfoLine(label: 'WhatsApp', value: doctor.phone),
              _InfoLine(label: 'Horario', value: doctor.workingHours),
              _InfoLine(
                label: 'Ubicación',
                value:
                    '${doctor.city}, ${doctor.provinceName}, ${doctor.region}',
              ),
              _InfoLine(
                label: 'Consultorio',
                value: doctor.officeAddress?.trim().isNotEmpty == true
                    ? doctor.officeAddress!
                    : 'Sin dirección exacta',
              ),
              _InfoLine(
                label: 'Experiencia',
                value: '${doctor.yearsExperience} años',
              ),
              if (doctor.submittedAt != null)
                _InfoLine(
                  label: 'Enviado',
                  value: DateFormat(
                    "d 'de' MMMM yyyy, HH:mm",
                    'es',
                  ).format(doctor.submittedAt!),
                ),
              if (doctor.reviewedAt != null)
                _InfoLine(
                  label: 'Revisado',
                  value: DateFormat(
                    "d 'de' MMMM yyyy, HH:mm",
                    'es',
                  ).format(doctor.reviewedAt!),
                ),
              if (doctor.reviewedBy != null)
                _InfoLine(label: 'Revisado por', value: doctor.reviewedBy!),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Acerca del médico',
            style: TextStyle(fontWeight: FontWeight.w800, color: colors.text),
          ),
          const SizedBox(height: 6),
          Text(
            doctor.about.trim().isEmpty ? 'Sin descripción.' : doctor.about,
            style: TextStyle(color: colors.muted, height: 1.45),
          ),
          const SizedBox(height: 16),
          Text(
            'Servicios',
            style: TextStyle(fontWeight: FontWeight.w800, color: colors.text),
          ),
          const SizedBox(height: 8),
          if (doctor.services.isEmpty)
            Text('No cargó servicios.', style: TextStyle(color: colors.muted))
          else
            ...doctor.services.map(
              (service) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(service.name),
                subtitle: Text('${service.durationMinutes} min'),
                trailing: Text(
                  formatPrice(service.price),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          if (doctor.rejectionReason?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 12),
            Material(
              color: AppColors.danger.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(
                  'Motivo de rechazo: ${doctor.rejectionReason}',
                  style: const TextStyle(color: AppColors.danger, height: 1.35),
                ),
              ),
            ),
          ],
          if (doctor.hasWhatsApp) ...[
            const SizedBox(height: 16),
            SecondaryPillButton(
              label: 'Abrir WhatsApp del médico',
              onPressed: () => openDoctorWhatsApp(doctor),
            ),
          ],
          const SizedBox(height: 16),
          if (doctor.published)
            SecondaryPillButton(
              label: _working ? 'Espera...' : 'Ocultar de pacientes',
              onPressed: _working ? null : () => _unpublish(doctor),
            )
          else
            PrimaryPillButton(
              label: _working ? 'Espera...' : 'Aprobar y publicar',
              onPressed: _working ? null : () => _approve(doctor),
            ),
          const SizedBox(height: 10),
          if (!doctor.published ||
              doctor.reviewStatus != DoctorReviewStatus.rejected)
            OutlinedButton(
              onPressed: _working ? null : () => _reject(doctor),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
              ),
              child: const Text('Rechazar perfil'),
            ),
        ],
      ),
    );
  }

  Future<void> _approve(Doctor doctor) async {
    final auth = context.read<AuthProvider>();
    setState(() => _working = true);
    try {
      await context.read<DoctorsProvider>().approveDoctor(
        doctor,
        adminEmail: auth.email,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil aprobado y visible para pacientes.')),
      );
      Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(auth.messageFor(error))));
      }
    } finally {
      if (mounted) {
        setState(() => _working = false);
      }
    }
  }

  Future<void> _unpublish(Doctor doctor) async {
    final auth = context.read<AuthProvider>();
    setState(() => _working = true);
    try {
      await context.read<DoctorsProvider>().unpublishDoctor(
        doctor,
        adminEmail: auth.email,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El perfil ya no es visible para pacientes.')),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(auth.messageFor(error))));
      }
    } finally {
      if (mounted) {
        setState(() => _working = false);
      }
    }
  }

  Future<void> _reject(Doctor doctor) async {
    final reasonController = TextEditingController(
      text: doctor.rejectionReason ?? '',
    );
    final reason = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rechazar perfil'),
          content: TextField(
            controller: reasonController,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Motivo',
              hintText: 'Ej. Falta el exequátur o la foto no es clara.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.pop(context, reasonController.text.trim()),
              child: const Text('Rechazar'),
            ),
          ],
        );
      },
    );
    reasonController.dispose();
    if (reason == null || !mounted) {
      return;
    }
    final auth = context.read<AuthProvider>();
    setState(() => _working = true);
    try {
      await context.read<DoctorsProvider>().rejectDoctor(
        doctor,
        reason: reason,
        adminEmail: auth.email,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil rechazado. El médico verá el motivo.')),
      );
      Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(auth.messageFor(error))));
      }
    } finally {
      if (mounted) {
        setState(() => _working = false);
      }
    }
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.of(context).surface,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: children),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: TextStyle(color: colors.muted)),
          ),
          Expanded(
            child: Text(
              value.trim().isEmpty ? '—' : value,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: colors.text,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
