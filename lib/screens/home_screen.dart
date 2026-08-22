import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/mock_data.dart';
import '../data/specialty_icons.dart';
import '../models/user_location.dart';
import '../providers/auth_provider.dart';
import '../providers/clinics_provider.dart';
import '../providers/doctors_provider.dart';
import '../providers/session_provider.dart';
import '../providers/shell_tab_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/doctor_avatar.dart';
import '../widgets/notifications_bell_button.dart';
import '../widgets/specialty_card.dart';
import '../widgets/theme_toggle_button.dart';
import 'change_location_screen.dart';
import 'specialists_screen.dart';
import 'specialties_screen.dart';
import 'clinics_screen.dart';
import 'doctor_profile_screen.dart';
import 'medical_services_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final location = context.watch<SessionProvider>().location;
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CitaMedic',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: colors.text,
                    ),
                  ),
                  Text(
                    'Servicio médico fácil',
                    style: TextStyle(color: colors.muted, fontSize: 12),
                  ),
                ],
              ),
              const Spacer(),
              const NotificationsBellButton(),
              const ThemeToggleButton(),
              IconButton(
                tooltip: 'Cerrar sesión',
                onPressed: () async {
                  context.read<SessionProvider>().clear();
                  await context.read<AuthProvider>().signOut();
                },
                icon: Icon(Icons.logout, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Hola, ${context.watch<SessionProvider>().firstName}',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: colors.text,
            ),
          ),
          if (context.watch<AuthProvider>().isGuest) ...[
            const SizedBox(height: 12),
            Material(
              color: colors.primarySoft,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    const Icon(Icons.person_outline, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Estás en modo invitado. Puedes ver especialidades, clínicas y médicos, pero no agendar citas.',
                        style: TextStyle(color: colors.text, height: 1.35),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          Text(
            context.watch<AuthProvider>().isGuest
                ? 'Explora especialidades, clínicas y médicos.'
                : 'Encuentra un especialista y agenda tu cita.',
            style: TextStyle(color: colors.muted),
          ),
          const SizedBox(height: 12),
          const _CurrentLocationRow(),
          const SizedBox(height: 22),
          const Text(
            'Ubicaciones favoritas',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 12),
          const _FavoriteLocationsSection(),
          const SizedBox(height: 22),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.08,
            children: [
              SpecialtyCard(
                title: 'Especialidades',
                subtitle: '${specialties.length} especialidades',
                icon: Icons.grid_view_rounded,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SpecialtiesScreen(),
                    ),
                  );
                },
              ),
              SpecialtyCard(
                title: 'Medicina general',
                subtitle: 'Consulta de rutina',
                icon: specialtyIcons['Medicina general'] ??
                    Icons.local_hospital_outlined,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SpecialistsScreen(
                        specialty: 'Medicina general',
                      ),
                    ),
                  );
                },
              ),
              SpecialtyCard(
                title: 'Clínicas',
                subtitle:
                    '${context.watch<ClinicsProvider>().nearby(location).length} centros',
                icon: Icons.apartment_outlined,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ClinicsScreen()),
                  );
                },
              ),
              SpecialtyCard(
                title: 'Servicios médicos',
                subtitle: '${medicalServices.length} estudios',
                icon: Icons.biotech_outlined,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MedicalServicesScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Text(
            'Otros servicios',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.15,
            children: [
              for (final service in homeServices)
                SpecialtyCard(
                  title: service,
                  icon: specialtyIcons[service] ?? Icons.medical_services,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SpecialistsScreen(specialty: service),
                      ),
                    );
                  },
                ),
            ],
          ),
          const SizedBox(height: 22),
          const _RegisteredDoctorsSection(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Destacados',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              TextButton(
                onPressed: () => context.read<ShellTabProvider>().goTo(1),
                child: const Text('Ver todos'),
              ),
            ],
          ),
          ...context
              .watch<DoctorsProvider>()
              .nearby(context.watch<SessionProvider>().location)
              .take(3)
              .map((doctor) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          SpecialistsScreen(specialty: doctor.specialty),
                    ),
                  );
                },
                tileColor: AppColors.of(context).surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                leading: DoctorAvatar(doctor: doctor),
                title: Text(
                  doctor.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(doctor.specialty),
                trailing: const Icon(Icons.chevron_right),
              ),
            );
          }),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => context.read<ShellTabProvider>().goTo(3),
            icon: const Icon(Icons.event_available_outlined),
            label: const Text('Mis citas'),
          ),
        ],
      ),
    );
  }
}

class _CurrentLocationRow extends StatelessWidget {
  const _CurrentLocationRow();
  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    final location = session.location;
    final isFavorite =
        location != null && session.isFavoriteLocation(location);

    return Row(
      children: [
        Expanded(
          child: _LocationChip(
            label: location?.label ?? 'Elige una ubicación',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ChangeLocationScreen(),
                ),
              );
            },
          ),
        ),
        IconButton(
          tooltip: isFavorite
              ? 'Quitar de favoritos'
              : 'Guardar ubicación favorita',
          onPressed: location == null
              ? null
              : () => session.toggleFavoriteLocation(location),
          icon: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            color: isFavorite ? AppColors.danger : AppColors.primary,
          ),
        ),
      ],
    );
  }
}

class _FavoriteLocationsSection extends StatelessWidget {
  const _FavoriteLocationsSection();

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionProvider>();
    final favorites = session.favoriteLocations;

    if (favorites.isEmpty) {
      return Text(
        'Marca una ubicación con el corazón para guardarla aquí.',
        style: TextStyle(color: AppColors.of(context).muted),
      );
    }

    return SizedBox(
      height: 108,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: favorites.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final item = favorites[index];
          final selected = item == session.location;
          return _FavoriteLocationCard(
            location: item,
            selected: selected,
            onTap: () => session.updateLocation(item),
            onRemove: () => session.toggleFavoriteLocation(item),
          );
        },
      ),
    );
  }
}

class _FavoriteLocationCard extends StatelessWidget {
  const _FavoriteLocationCard({
    required this.location,
    required this.selected,
    required this.onTap,
    required this.onRemove,
  });

  final UserLocation location;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Material(
      color: selected ? colors.primarySoft : colors.surface,
      elevation: selected ? 0 : 2,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: 168,
          padding: const EdgeInsets.fromLTRB(12, 12, 4, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected ? AppColors.primary : colors.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.location_on,
                    size: 18,
                    color: AppColors.location,
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: onRemove,
                    child: const Icon(
                      Icons.favorite,
                      size: 18,
                      color: AppColors.danger,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                location.city,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: colors.text,
                ),
              ),
              Text(
                '${location.province}, ${location.department}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: colors.muted, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocationChip extends StatelessWidget {
  const _LocationChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: ActionChip(
        avatar: const Icon(
          Icons.location_on_outlined,
          size: 18,
          color: AppColors.location,
        ),
        label: Text(label),
        onPressed: onTap,
        backgroundColor: AppColors.of(context).primarySoft,
        side: BorderSide.none,
      ),
    );
  }
}

class _RegisteredDoctorsSection extends StatelessWidget {
  const _RegisteredDoctorsSection();

  @override
  Widget build(BuildContext context) {
    final doctors = context.watch<DoctorsProvider>().registeredDoctors;
    if (doctors.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Médicos registrados',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
        ),
        const SizedBox(height: 6),
        Text(
          'Perfiles publicados por profesionales en CitaMedic.',
          style: TextStyle(color: AppColors.of(context).muted, fontSize: 13),
        ),
        const SizedBox(height: 12),
        ...doctors.map((doctor) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DoctorProfileScreen(doctorId: doctor.id),
                  ),
                );
              },
              tileColor: AppColors.of(context).surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              leading: DoctorAvatar(doctor: doctor),
              title: Text(
                doctor.name,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              subtitle: Text(
                '${doctor.specialty} · ${doctor.hospital}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.chevron_right),
            ),
          );
        }),
        const SizedBox(height: 12),
      ],
    );
  }
}
