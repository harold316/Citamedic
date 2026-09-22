import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/mock_data.dart';
import '../models/doctor.dart';
import '../models/medical_service.dart';
import '../providers/doctors_provider.dart';
import '../providers/session_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/doctor_carousel_card.dart';
import '../widgets/notifications_bell_button.dart';
import '../widgets/service_list_tile.dart';
import 'doctor_profile_screen.dart';

class SpecialistsScreen extends StatefulWidget {
  const SpecialistsScreen({super.key, required this.specialty});

  final String specialty;

  @override
  State<SpecialistsScreen> createState() => _SpecialistsScreenState();
}

class _SpecialistsScreenState extends State<SpecialistsScreen> {
  static const _carouselItemExtent = 224.0;

  String? _selectedDoctorId;
  final _carouselController = ScrollController();

  @override
  void dispose() {
    _carouselController.dispose();
    super.dispose();
  }

  Doctor _selectedDoctor(List<Doctor> doctors) {
    return doctors.firstWhere(
      (doctor) => doctor.id == _selectedDoctorId,
      orElse: () => doctors.first,
    );
  }

  void _selectDoctor(Doctor doctor) {
    if (_selectedDoctorId == doctor.id) return;
    setState(() => _selectedDoctorId = doctor.id);
  }

  void _onCarouselScroll(List<Doctor> doctors) {
    if (!_carouselController.hasClients || doctors.isEmpty) return;
    final index = (_carouselController.offset / _carouselItemExtent)
        .round()
        .clamp(0, doctors.length - 1);
    _selectDoctor(doctors[index]);
  }

  @override
  Widget build(BuildContext context) {
    final location = context.watch<SessionProvider>().location;
    final doctorsProvider = context.watch<DoctorsProvider>();
    final doctors = doctorsProvider.bySpecialty(widget.specialty, location);
    final selected = doctors.isEmpty ? null : _selectedDoctor(doctors);
    final services = selected?.services ?? const <MedicalService>[];

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.specialty == defaultSpecialty
              ? widget.specialty
              : '${widget.specialty} especialista',
        ),
        actions: const [
          NotificationsBellButton(),
        ],
      ),
      body: doctors.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No hay profesionales de esta especialidad en tu ubicación.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              children: [
                SizedBox(
                  height: 338,
                  child: NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      if (notification.metrics.axis == Axis.horizontal) {
                        _onCarouselScroll(doctors);
                      }
                      return false;
                    },
                    child: ListView.separated(
                      controller: _carouselController,
                      scrollDirection: Axis.horizontal,
                      itemCount: doctors.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 14),
                      itemBuilder: (context, index) {
                        final doctor = doctors[index];
                        return DoctorCarouselCard(
                          doctor: doctor,
                          selected: doctor.id == selected?.id,
                          isFavorite: doctorsProvider.isFavorite(doctor.id),
                          onFavorite: () =>
                              doctorsProvider.toggleFavorite(doctor.id),
                          onTap: () {
                            _selectDoctor(doctor);
                            _openProfile(context, doctor);
                          },
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    _RoundAction(
                      icon: Icons.search,
                      onTap: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 10),
                    const _RoundAction(icon: Icons.tune),
                  ],
                ),
                const SizedBox(height: 18),
                ...services.asMap().entries.map((entry) {
                  final service = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ServiceListTile(
                      service: service,
                      highlighted: entry.key == 0,
                      onTap: () => _openProfile(context, selected!, service),
                    ),
                  );
                }),
              ],
            ),
    );
  }

  void _openProfile(
    BuildContext context,
    Doctor doctor, [
    MedicalService? service,
  ]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DoctorProfileScreen(
          doctorId: doctor.id,
          highlightedServiceId: service?.id,
        ),
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.of(context).surface,
      shape: const CircleBorder(),
      elevation: 1,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
      ),
    );
  }
}
