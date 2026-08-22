import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/clinic.dart';
import '../models/doctor.dart';
import '../models/doctor_review_status.dart';
import '../providers/appointments_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/clinics_provider.dart';
import '../providers/doctors_provider.dart';
import '../providers/session_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/notifications_bell_button.dart';
import '../widgets/theme_toggle_button.dart';
import 'admin_clinic_review_screen.dart';
import 'admin_doctor_review_screen.dart';

enum _AdminFilter { pending, published, rejected, all }

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  _AdminFilter _filter = _AdminFilter.pending;
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final doctors = context.watch<DoctorsProvider>().registeredDoctors;
    final clinics = context.watch<ClinicsProvider>().registeredClinics;
    final appointments = context.watch<AppointmentsProvider>().appointments;
    final pending = doctors
        .where((item) => item.reviewStatus == DoctorReviewStatus.pending)
        .toList();
    final pendingClinics = clinics
        .where((item) => item.reviewStatus == DoctorReviewStatus.pending)
        .toList();
    final published = doctors.where((item) => item.published).toList();
    final rejected = doctors
        .where((item) => item.reviewStatus == DoctorReviewStatus.rejected)
        .toList();
    final visible = _filtered(doctors);
    final specialties = <String, int>{};
    for (final doctor in doctors) {
      specialties[doctor.specialty] = (specialties[doctor.specialty] ?? 0) + 1;
    }
    final topSpecialties = specialties.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final avgScore = doctors.isEmpty
        ? 0
        : (doctors
                    .map((item) => item.profileScore)
                    .fold<int>(0, (sum, value) => sum + value) /
                doctors.length)
            .round();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de administración'),
        actions: [
          const NotificationsBellButton(),
          const ThemeToggleButton(),
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              context.read<SessionProvider>().clear();
              await context.read<AuthProvider>().signOut();
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Text(
            'Hola, ${context.watch<AuthProvider>().displayName}. Revisa los perfiles médicos y las clínicas antes de publicarlos.',
            style: TextStyle(color: colors.muted, height: 1.35),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _KpiCard(
                label: 'Pendientes',
                value: '${pending.length}',
                icon: Icons.hourglass_top_rounded,
                color: const Color(0xFFE8A838),
              ),
              _KpiCard(
                label: 'Publicados',
                value: '${published.length}',
                icon: Icons.verified_outlined,
                color: AppColors.primary,
              ),
              _KpiCard(
                label: 'Rechazados',
                value: '${rejected.length}',
                icon: Icons.gpp_bad_outlined,
                color: AppColors.danger,
              ),
              _KpiCard(
                label: 'Clínicas pendientes',
                value: '${pendingClinics.length}',
                icon: Icons.apartment_outlined,
                color: const Color(0xFF2563EB),
              ),
              _KpiCard(
                label: 'Citas',
                value: '${appointments.length}',
                icon: Icons.event_available_outlined,
                color: colors.text,
              ),
              _KpiCard(
                label: 'Completitud',
                value: '$avgScore%',
                icon: Icons.analytics_outlined,
                color: colors.text,
              ),
            ],
          ),
          if (topSpecialties.isNotEmpty) ...[
            const SizedBox(height: 22),
            Text(
              'Especialidades registradas',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
                color: colors.text,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final item in topSpecialties.take(8))
                  Chip(
                    label: Text('${item.key} · ${item.value}'),
                    backgroundColor: colors.primarySoft,
                    side: BorderSide.none,
                  ),
              ],
            ),
          ],
          const SizedBox(height: 22),
          TextField(
            controller: _query,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Buscar médico, clínica o especialidad',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final item in _AdminFilter.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(_filterLabel(item, pending.length)),
                      selected: _filter == item,
                      onSelected: (_) => setState(() => _filter = item),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (visible.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Text(
                doctors.isEmpty
                    ? 'Todavía no hay médicos registrados.'
                    : 'No hay perfiles en este filtro.',
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.muted),
              ),
            )
          else
            ...visible.map(
              (doctor) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _DoctorReviewTile(
                  doctor: doctor,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            AdminDoctorReviewScreen(doctorId: doctor.id),
                      ),
                    );
                  },
                ),
              ),
            ),
          const SizedBox(height: 28),
          Text(
            'Clínicas registradas',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: colors.text,
            ),
          ),
          const SizedBox(height: 12),
          if (clinics.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'Todavía no hay clínicas registradas.',
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.muted),
              ),
            )
          else
            ...clinics.map(
              (clinic) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ClinicReviewTile(
                  clinic: clinic,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            AdminClinicReviewScreen(clinicId: clinic.id),
                      ),
                    );
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Doctor> _filtered(List<Doctor> doctors) {
    final query = _query.text.trim().toLowerCase();
    final items = doctors.where((doctor) {
      switch (_filter) {
        case _AdminFilter.pending:
          if (doctor.reviewStatus != DoctorReviewStatus.pending) {
            return false;
          }
        case _AdminFilter.published:
          if (!doctor.published) {
            return false;
          }
        case _AdminFilter.rejected:
          if (doctor.reviewStatus != DoctorReviewStatus.rejected) {
            return false;
          }
        case _AdminFilter.all:
          break;
      }
      if (query.isEmpty) {
        return true;
      }
      final haystack =
          '${doctor.name} ${doctor.specialty} ${doctor.hospital} ${doctor.city} ${doctor.credentials}'
              .toLowerCase();
      return haystack.contains(query);
    }).toList();
    items.sort((a, b) {
      final byStatus = a.reviewStatus.index.compareTo(b.reviewStatus.index);
      if (byStatus != 0) {
        return byStatus;
      }
      return a.name.compareTo(b.name);
    });
    return items;
  }

  String _filterLabel(_AdminFilter filter, int pendingCount) {
    switch (filter) {
      case _AdminFilter.pending:
        return 'Pendientes ($pendingCount)';
      case _AdminFilter.published:
        return 'Publicados';
      case _AdminFilter.rejected:
        return 'Rechazados';
      case _AdminFilter.all:
        return 'Todos';
    }
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return SizedBox(
      width: 158,
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 10),
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: colors.text,
                ),
              ),
              Text(label, style: TextStyle(color: colors.muted, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}

class _DoctorReviewTile extends StatelessWidget {
  const _DoctorReviewTile({required this.doctor, required this.onTap});

  final Doctor doctor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: doctor.hasCustomPhoto
                    ? Image.network(
                        doctor.photoUrl,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _photoFallback(colors),
                      )
                    : _photoFallback(colors),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctor.name,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: colors.text,
                      ),
                    ),
                    Text(
                      doctor.specialty,
                      style: TextStyle(color: colors.muted, fontSize: 13),
                    ),
                    Text(
                      doctor.hospital,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: colors.muted, fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _StatusChip(status: doctor.reviewStatus),
                        Text(
                          'Perfil ${doctor.profileScore}%',
                          style: TextStyle(
                            color: colors.muted,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (doctor.submittedAt != null)
                          Text(
                            DateFormat('d MMM', 'es').format(doctor.submittedAt!),
                            style: TextStyle(color: colors.muted, fontSize: 12),
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

  Widget _photoFallback(AppColors colors) {
    return Container(
      width: 64,
      height: 64,
      color: colors.primarySoft,
      alignment: Alignment.center,
      child: const Icon(Icons.person, color: AppColors.primary),
    );
  }
}

class _ClinicReviewTile extends StatelessWidget {
  const _ClinicReviewTile({required this.clinic, required this.onTap});

  final Clinic clinic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  clinic.photoUrl,
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    width: 64,
                    height: 64,
                    color: colors.primarySoft,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.apartment_outlined,
                      color: AppColors.primary,
                    ),
                  ),
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
                        color: colors.text,
                      ),
                    ),
                    Text(
                      clinic.city,
                      style: TextStyle(color: colors.muted, fontSize: 13),
                    ),
                    Text(
                      clinic.address,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: colors.muted, fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    _StatusChip(status: clinic.reviewStatus),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final DoctorReviewStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      DoctorReviewStatus.pending => const Color(0xFFE8A838),
      DoctorReviewStatus.approved => AppColors.primary,
      DoctorReviewStatus.rejected => AppColors.danger,
      DoctorReviewStatus.draft => AppColors.of(context).muted,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
