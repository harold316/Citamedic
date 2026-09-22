import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../data/locations.dart';
import '../data/mock_data.dart';
import '../models/doctor.dart';
import '../models/doctor_review_status.dart';
import '../models/medical_service.dart';
import '../providers/appointments_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/doctors_provider.dart';
import '../providers/session_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/appointment_card.dart';
import '../widgets/doctor_medical_card.dart';
import 'appointment_detail_screen.dart';
import '../widgets/location_selectors.dart';
import '../widgets/notifications_bell_button.dart';
import '../widgets/primary_pill_button.dart';
import '../widgets/specialty_category_dropdown.dart';
import '../widgets/delete_account_button.dart';
import '../widgets/support_tech_button.dart';
import '../widgets/theme_toggle_button.dart';
import 'office_location_screen.dart';

class DoctorHomeScreen extends StatefulWidget {
  const DoctorHomeScreen({super.key});

  @override
  State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen> {
  final _nameController = TextEditingController();
  final _credentialsController = TextEditingController();
  final _hospitalController = TextEditingController();
  final _phoneController = TextEditingController();
  final _hoursController = TextEditingController();
  final _aboutController = TextEditingController();
  final _addressController = TextEditingController();
  final _yearsController = TextEditingController(text: '1');
  final _services = <_ServiceDraft>[];

  String _specialty = defaultSpecialty;
  String _country = defaultCountry;
  String _department = defaultDepartment;
  String _province = defaultProvince;
  String _city = defaultCity;
  DoctorReviewStatus _reviewStatus = DoctorReviewStatus.draft;
  String? _rejectionReason;
  bool _loading = true;
  bool _saving = false;
  String? _error;
  String? _photoUrl;
  XFile? _photoFile;
  Uint8List? _photoBytes;
  DoctorsProvider? _doctors;

  @override
  void initState() {
    super.initState();
    for (final controller in [
      _nameController,
      _credentialsController,
      _hospitalController,
    ]) {
      controller.addListener(() {
        if (!_loading && mounted) {
          setState(() {});
        }
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final doctors = context.read<DoctorsProvider>();
    if (_doctors != doctors) {
      _doctors?.removeListener(_onRegistrationDraft);
      _doctors = doctors;
      _doctors!.addListener(_onRegistrationDraft);
    }
  }

  void _onRegistrationDraft() {
    if (!mounted || _loading) {
      return;
    }
    final doctors = _doctors;
    final draft = doctors?.registrationDraft;
    if (doctors == null || draft == null) {
      return;
    }
    if (_hospitalController.text.trim().isEmpty &&
        draft.hospital.trim().isNotEmpty) {
      _fillForm(draft, context.read<AuthProvider>());
      _photoBytes = doctors.registrationPhotoBytes ?? _photoBytes;
      setState(() {});
    }
  }

  @override
  void dispose() {
    _doctors?.removeListener(_onRegistrationDraft);
    _nameController.dispose();
    _credentialsController.dispose();
    _hospitalController.dispose();
    _phoneController.dispose();
    _hoursController.dispose();
    _aboutController.dispose();
    _addressController.dispose();
    _yearsController.dispose();
    for (final service in _services) {
      service.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    final doctors = context.read<DoctorsProvider>();
    _photoBytes = doctors.registrationPhotoBytes;
    _fillForm(doctors.registrationDraft, auth);
    if (mounted) {
      setState(() => _loading = false);
    }

    try {
      final saved = await doctors.loadProfile(auth.uid);
      if (!mounted) {
        return;
      }
      final draft = doctors.registrationDraft;
      final profile = saved == null
          ? draft
          : (draft == null ? saved : saved.mergeWithDraft(draft));
      if (profile != null) {
        _fillForm(profile, auth);
      }
      _photoBytes = doctors.registrationPhotoBytes ?? _photoBytes;
      setState(() {});
    } catch (error) {
      if (mounted) {
        setState(() => _error = auth.messageFor(error));
      }
    }
  }

  void _fillForm(Doctor? saved, AuthProvider auth) {
    _nameController.text = saved?.name ?? auth.displayName;
    _credentialsController.text = saved?.credentials ?? '';
    _hospitalController.text = saved?.hospital ?? '';
    _phoneController.text = saved?.phone ?? '';
    _hoursController.text = saved?.workingHours ?? 'Lun a Vie, 9:00 - 18:00';
    _aboutController.text = saved?.about ?? '';
    _addressController.text = saved?.officeAddress ?? '';
    _photoUrl = _storedPhotoUrl(saved?.photoUrl);
    _yearsController.text = '${saved?.yearsExperience ?? 1}';
    _specialty = saved != null && allCategories.contains(saved.specialty)
        ? saved.specialty
        : defaultSpecialty;
    _country = saved?.country ?? defaultCountry;
    _department = saved?.department ?? defaultDepartment;
    _province = saved?.province ?? defaultProvince;
    _city = saved?.city ?? defaultCity;
    _reviewStatus = saved?.reviewStatus ?? DoctorReviewStatus.draft;
    _rejectionReason = saved?.rejectionReason;

    for (final service in _services) {
      service.dispose();
    }
    _services
      ..clear()
      ..addAll(
        (saved?.services.isNotEmpty == true
                ? saved!.services
                : [
                    const MedicalService(
                      id: 'consulta',
                      name: 'Consulta',
                      price: 1500,
                      durationMinutes: 30,
                    ),
                  ])
            .map(_ServiceDraft.fromService),
      );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mi perfil'),
          actions: [
            const NotificationsBellButton(),
            const SupportTechIconButton(),
            const ThemeToggleButton(),
            IconButton(
              tooltip: 'Cerrar sesión',
              onPressed: () async {
                context.read<DoctorsProvider>().forgetRegistration();
                context.read<SessionProvider>().clear();
                await context.read<AuthProvider>().signOut();
              },
              icon: const Icon(Icons.logout),
            ),
          ],
          bottom: TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.of(context).muted,
            indicatorColor: AppColors.primary,
            tabs: const [
              Tab(icon: Icon(Icons.event_available_outlined), text: 'Citas'),
              Tab(icon: Icon(Icons.person_outline), text: 'Perfil'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            const _DoctorAppointmentsTab(),
            _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    children: [
                Text(
                  'Hola, ${auth.displayName}. Completa tus datos y envíalos a revisión. Un administrador verificará tu perfil antes de publicarlo.',
                  style: TextStyle(color: AppColors.of(context).muted),
                ),
                const SizedBox(height: 16),
                _ReviewStatusBanner(
                  status: _reviewStatus,
                  rejectionReason: _rejectionReason,
                ),
                const SizedBox(height: 16),
                DoctorMedicalCard(
                  name: _nameController.text,
                  specialty: _specialty,
                  credentials: _credentialsController.text,
                  hospital: _hospitalController.text,
                  photoUrl: _photoUrl,
                  photoBytes: _photoBytes,
                ),
                const SizedBox(height: 16),
                _UploadTile(
                  label: 'Foto de perfil',
                  hint: 'Foto de frente con fondo claro y ropa de trabajo.',
                  icon: Icons.photo_camera_outlined,
                  filled: _hasProfilePhoto,
                  onTap: _pickImage,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nombre profesional',
                    hintText: 'Ej. Dr. Juan Pérez',
                  ),
                ),
                const SizedBox(height: 12),
                SpecialtyCategoryDropdown(
                  value: _specialty,
                  onChanged: (value) => setState(() => _specialty = value),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _credentialsController,
                  decoration: const InputDecoration(
                    labelText: 'Credenciales o matrícula',
                    hintText: 'Ej. Especialidad en Santa Cruz. Mat. Prof. ----',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _hospitalController,
                  decoration: const InputDecoration(
                    labelText: 'Lugar de trabajo',
                    hintText: 'Clínica, hospital o establecimiento de salud',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'WhatsApp',
                    hintText: 'Ej. 18095551234',
                    helperText: 'Incluye código de país para que los pacientes te escriban.',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _hoursController,
                  decoration: const InputDecoration(
                    labelText: 'Horario de atención',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _yearsController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Años de experiencia',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _aboutController,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Acerca de ti',
                    alignLabelWithHint: true,
                    hintText:
                        'Ej. Médico especialista en [Tu Especialidad] con más de [X] años de experiencia clínica. Me enfoco en brindar diagnósticos precisos y tratamientos personalizados con un trato humano, empático y de escucha activa.',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Dirección del consultorio',
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OfficeLocationScreen(doctorId: auth.uid),
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.my_location,
                    color: AppColors.location,
                  ),
                  label: const Text('Añadir ubicación GPS del consultorio'),
                ),
                const SizedBox(height: 16),
                Text(
                  'Ubicación',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.of(context).text,
                  ),
                ),
                const SizedBox(height: 10),
                LocationSelectors(
                  country: _country,
                  department: _department,
                  province: _province,
                  city: _city,
                  onCountryChanged: _onCountryChanged,
                  onDepartmentChanged: _onDepartmentChanged,
                  onProvinceChanged: _onProvinceChanged,
                  onCityChanged: (value) => setState(() => _city = value),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Servicios que ofreces',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: AppColors.of(context).text,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        setState(() => _services.add(_ServiceDraft()));
                      },
                      icon: const Icon(Icons.add, color: AppColors.primary),
                      label: const Text('Agregar'),
                    ),
                  ],
                ),
                ..._services.asMap().entries.map((entry) {
                  final index = entry.key;
                  final service = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppColors.of(context).surface,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 8, 14),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: service.nameController,
                                    decoration: const InputDecoration(
                                      labelText: 'Servicio',
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: _services.length == 1
                                      ? null
                                      : () {
                                          setState(() {
                                            _services.removeAt(index).dispose();
                                          });
                                        },
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: AppColors.danger,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: service.priceController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Precio (Bs)',
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: service.durationController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Minutos',
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: const TextStyle(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                PrimaryPillButton(
                  label: _saving ? 'Enviando...' : _submitLabel,
                  onPressed: _saving ? null : _save,
                ),
                const SizedBox(height: 16),
                DeleteAccountButton(
                  onBeforeDelete: () async {
                    context.read<DoctorsProvider>().forgetRegistration();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool get _hasProfilePhoto {
    return _photoBytes != null || _storedPhotoUrl(_photoUrl) != null;
  }

  String get _submitLabel {
    switch (_reviewStatus) {
      case DoctorReviewStatus.pending:
        return 'Actualizar solicitud';
      case DoctorReviewStatus.rejected:
        return 'Volver a enviar a revisión';
      case DoctorReviewStatus.approved:
        return 'Guardar y volver a revisión';
      case DoctorReviewStatus.draft:
        return 'Enviar a revisión';
    }
  }

  String? _storedPhotoUrl(String? url) {
    if (url == null || url.trim().isEmpty || url == defaultDoctorPhoto) {
      return null;
    }
    return url;
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Galería'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Cámara'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
        );
      },
    );
    if (source == null) {
      return;
    }

    final picked = await ImagePicker().pickImage(
      source: source,
      imageQuality: 75,
      maxWidth: 1600,
    );
    if (picked == null) {
      return;
    }
    final bytes = await picked.readAsBytes();
    if (!mounted) {
      return;
    }
    setState(() {
      _photoFile = picked;
      _photoBytes = bytes;
    });
  }

  void _onCountryChanged(String value) {
    final department = catalogDepartments(value).first;
    final province = catalogProvinces(value, department).first;
    setState(() {
      _country = value;
      _department = department;
      _province = province;
      _city = catalogCities(value, department, province).first;
    });
  }

  void _onDepartmentChanged(String value) {
    final province = catalogProvinces(_country, value).first;
    setState(() {
      _department = value;
      _province = province;
      _city = catalogCities(_country, value, province).first;
    });
  }

  void _onProvinceChanged(String value) {
    setState(() {
      _province = value;
      _city = catalogCities(_country, _department, value).first;
    });
  }

  Future<void> _save() async {
    final auth = context.read<AuthProvider>();
    final name = _nameController.text.trim();
    final hospital = _hospitalController.text.trim();
    if (name.isEmpty || hospital.isEmpty) {
      setState(
        () => _error = 'Escribe tu nombre profesional y el lugar de trabajo.',
      );
      return;
    }
    if (_phoneController.text.replaceAll(RegExp(r'\D'), '').length < 8) {
      setState(
        () => _error =
            'Escribe el número con código de país, por ejemplo 18095551234.',
      );
      return;
    }

    final services = _services
        .map((draft) => draft.toService())
        .where((service) => service.name.trim().isNotEmpty)
        .toList();
    if (services.isEmpty) {
      setState(
        () => _error = 'Agrega al menos un servicio antes de enviar a revisión.',
      );
      return;
    }
    if (!_hasProfilePhoto) {
      setState(
        () => _error = 'Sube tu foto de perfil antes de enviar a revisión.',
      );
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final doctors = context.read<DoctorsProvider>();
      final existing = await doctors.loadProfile(auth.uid);
      var photoUrl =
          _storedPhotoUrl(_photoUrl) ?? _storedPhotoUrl(existing?.photoUrl);
      if (_photoFile != null) {
        photoUrl = await doctors.uploadImage(
          uid: auth.uid,
          name: 'photo',
          file: _photoFile!,
        );
      }
      photoUrl ??= defaultDoctorPhoto;
      await doctors.saveProfile(
        Doctor(
          id: auth.uid,
          name: name,
          credentials: _credentialsController.text.trim(),
          specialty: _specialty,
          photoUrl: photoUrl,
          rating: existing?.rating ?? 5,
          reviewCount: existing?.reviewCount ?? 0,
          yearsExperience: int.tryParse(_yearsController.text.trim()) ?? 1,
          patientsCount: existing?.patientsCount ?? 0,
          workingHours: _hoursController.text.trim().isEmpty
              ? 'Lun a Vie, 9:00 - 18:00'
              : _hoursController.text.trim(),
          about: _aboutController.text.trim(),
          hospital: hospital,
          phone: _phoneController.text.trim(),
          city: _city,
          country: _country,
          department: _department,
          province: _province,
          officeAddress: _addressController.text.trim(),
          latitude: existing?.latitude,
          longitude: existing?.longitude,
          published: false,
          reviewStatus: DoctorReviewStatus.pending,
          submittedAt: DateTime.now(),
          services: services,
        ),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _photoUrl = _storedPhotoUrl(photoUrl);
        _photoFile = null;
        _reviewStatus = DoctorReviewStatus.pending;
        _rejectionReason = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Solicitud enviada. Un administrador verificará tus datos antes de publicar el perfil.',
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        setState(() => _error = auth.messageFor(error));
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }
}

class _ReviewStatusBanner extends StatelessWidget {
  const _ReviewStatusBanner({
    required this.status,
    this.rejectionReason,
  });

  final DoctorReviewStatus status;
  final String? rejectionReason;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final (Color color, String text) = switch (status) {
      DoctorReviewStatus.draft => (
        colors.muted,
        'Tu perfil aún no es visible. Complétalo y envíalo a revisión.',
      ),
      DoctorReviewStatus.pending => (
        const Color(0xFFE8A838),
        'Tu perfil está en revisión. Te avisaremos cuando un administrador lo verifique. Contacta a soporte técnico para la verificación.',
      ),
      DoctorReviewStatus.approved => (
        AppColors.primary,
        'Tu perfil está publicado. Si cambias datos, volverá a revisión.',
      ),
      DoctorReviewStatus.rejected => (
        AppColors.danger,
        rejectionReason?.trim().isNotEmpty == true
            ? 'Rechazado: $rejectionReason'
            : 'Tu perfil fue rechazado. Corrige los datos y vuelve a enviarlo.',
      ),
    };

    return Material(
      color: color.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Text(
          text,
          style: TextStyle(color: color, height: 1.35, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _DoctorAppointmentsTab extends StatelessWidget {
  const _DoctorAppointmentsTab();

  @override
  Widget build(BuildContext context) {
    final appointments = context.watch<AppointmentsProvider>().appointments;
    final colors = AppColors.of(context);

    if (appointments.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.event_busy_outlined, size: 48, color: AppColors.primary),
              const SizedBox(height: 12),
              Text(
                'Aún no tienes citas agendadas.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: colors.text,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Cuando un paciente reserve contigo, la cita aparecerá aquí.',
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.muted),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      itemCount: appointments.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Text(
            'Citas que te agendaron los pacientes',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: colors.text,
            ),
          );
        }
        final appointment = appointments[index - 1];
        return AppointmentCard(
          appointment: appointment,
          title: appointment.patientName,
          subtitle: appointment.patientEmail.isEmpty
              ? appointment.serviceName
              : '${appointment.serviceName} · ${appointment.patientEmail}',
          onTap: () => openAppointmentDetail(context, appointment),
          onDelete: () => deleteAppointmentWithConfirm(
            context,
            appointment: appointment,
          ),
          onAccept: () => acceptAppointmentWithConfirm(
            context,
            appointment: appointment,
          ),
          onReschedule: () => rescheduleAppointment(
            context,
            appointment: appointment,
          ),
        );
      },
    );
  }
}

class _UploadTile extends StatelessWidget {
  const _UploadTile({
    required this.label,
    required this.icon,
    required this.filled,
    required this.onTap,
    this.hint,
  });

  final String label;
  final String? hint;
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled
          ? AppColors.of(context).primarySoft
          : AppColors.of(context).surface,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
          child: Column(
            children: [
              Icon(
                filled ? Icons.check_circle : icon,
                color: AppColors.primary,
              ),
              const SizedBox(height: 8),
              Text(
                filled ? '$label lista' : label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.of(context).text,
                ),
              ),
              if (hint != null && hint!.trim().isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  hint!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.of(context).muted,
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ServiceDraft {
  _ServiceDraft({
    String? id,
    String name = 'Consulta',
    String price = '1500',
    String duration = '30',
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString(),
       nameController = TextEditingController(text: name),
       priceController = TextEditingController(text: price),
       durationController = TextEditingController(text: duration);

  factory _ServiceDraft.fromService(MedicalService service) {
    return _ServiceDraft(
      id: service.id,
      name: service.name,
      price: service.price.toStringAsFixed(0),
      duration: '${service.durationMinutes}',
    );
  }

  final String id;
  final TextEditingController nameController;
  final TextEditingController priceController;
  final TextEditingController durationController;

  MedicalService toService() {
    return MedicalService(
      id: id,
      name: nameController.text.trim(),
      price: double.tryParse(priceController.text.trim()) ?? 0,
      durationMinutes: int.tryParse(durationController.text.trim()) ?? 30,
    );
  }

  void dispose() {
    nameController.dispose();
    priceController.dispose();
    durationController.dispose();
  }
}
