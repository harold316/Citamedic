import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../data/locations.dart';
import '../models/clinic.dart';
import '../models/clinic_photo_draft.dart';
import '../models/doctor_review_status.dart';
import '../models/medical_service.dart';
import '../providers/auth_provider.dart';
import '../providers/clinics_provider.dart';
import '../providers/session_provider.dart';
import '../theme/app_theme.dart';
import '../utils/gps.dart';
import '../utils/maps.dart';
import '../widgets/clinic_photo_grid.dart';
import '../widgets/delete_account_button.dart';
import '../widgets/gps_capture_tile.dart';
import '../widgets/location_selectors.dart';
import '../widgets/notifications_bell_button.dart';
import '../widgets/primary_pill_button.dart';
import '../widgets/service_editor_list.dart';
import '../widgets/support_tech_button.dart';
import '../widgets/theme_toggle_button.dart';

class ClinicHomeScreen extends StatefulWidget {
  const ClinicHomeScreen({super.key});

  @override
  State<ClinicHomeScreen> createState() => _ClinicHomeScreenState();
}

class _ClinicHomeScreenState extends State<ClinicHomeScreen> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();
  final _aboutController = TextEditingController();
  final _photos = <ClinicPhotoDraft>[];
  final _services = <ServiceDraft>[];

  String _country = defaultCountry;
  String _department = defaultDepartment;
  String _province = defaultProvince;
  String _city = defaultCity;
  double? _latitude;
  double? _longitude;
  bool _locating = false;
  DoctorReviewStatus _reviewStatus = DoctorReviewStatus.draft;
  String? _rejectionReason;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _aboutController.dispose();
    for (final service in _services) {
      service.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    final clinics = context.read<ClinicsProvider>();
    _fillForm(clinics.registrationDraft, auth, clinics);
    if (mounted) {
      setState(() => _loading = false);
    }

    try {
      final saved = await clinics.loadProfile(auth.uid);
      if (!mounted) {
        return;
      }
      final draft = clinics.registrationDraft;
      final profile = saved ?? draft;
      if (profile != null) {
        _fillForm(profile, auth, clinics);
      }
      setState(() {});
    } catch (error) {
      if (mounted) {
        setState(() => _error = auth.messageFor(error));
      }
    }
  }

  void _fillForm(Clinic? saved, AuthProvider auth, ClinicsProvider clinics) {
    _nameController.text = saved?.name ?? auth.displayName;
    _addressController.text = saved?.address ?? '';
    _phoneController.text = saved?.phone ?? '';
    _aboutController.text = saved?.about ?? '';
    _country = saved?.country ?? defaultCountry;
    _department = saved?.department ?? defaultDepartment;
    _province = saved?.province ?? defaultProvince;
    _city = saved?.city ?? defaultCity;
    _latitude = saved?.latitude;
    _longitude = saved?.longitude;
    _reviewStatus = saved?.reviewStatus ?? DoctorReviewStatus.draft;
    _rejectionReason = saved?.rejectionReason;
    _photos
      ..clear()
      ..addAll(
        clinics.registrationPhotos.isNotEmpty
            ? clinics.registrationPhotos
            : [
                for (final url in saved?.gallery ?? const <String>[])
                  ClinicPhotoDraft(url: url),
              ],
      );
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
            .map(ServiceDraft.fromService),
      );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final colors = AppColors.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi clínica'),
        actions: [
          const NotificationsBellButton(),
          const SupportTechIconButton(),
          const ThemeToggleButton(),
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: () async {
              context.read<ClinicsProvider>().forgetRegistration();
              context.read<SessionProvider>().clear();
              await context.read<AuthProvider>().signOut();
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                Text(
                  'Hola, ${auth.displayName}. Completa los datos de tu centro y envíalos a revisión.',
                  style: TextStyle(color: colors.muted),
                ),
                const SizedBox(height: 16),
                _StatusBanner(
                  status: _reviewStatus,
                  rejectionReason: _rejectionReason,
                ),
                const SizedBox(height: 16),
                ClinicPhotoGrid(
                  photos: _photos,
                  onAdd: _addClinicPhotos,
                  onRemove: (index) {
                    setState(() => _photos.removeAt(index));
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Nombre de la clínica',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _addressController,
                  decoration: const InputDecoration(
                    labelText: 'Dirección',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'WhatsApp o teléfono',
                    hintText: 'Ej. 18095551234',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _aboutController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Acerca de la clínica',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Ubicación',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: colors.text,
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
                const SizedBox(height: 12),
                GpsCaptureTile(
                  latitude: _latitude,
                  longitude: _longitude,
                  locating: _locating,
                  onCapture: _captureGps,
                  onOpenMap: () {
                    openClinicMap(
                      Clinic(
                        id: auth.uid,
                        name: _nameController.text.trim(),
                        city: _city,
                        address: _addressController.text.trim(),
                        photoUrl: defaultClinicPhoto,
                        rating: 5,
                        latitude: _latitude,
                        longitude: _longitude,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                ServiceEditorList(
                  services: _services,
                  onAdd: () => setState(() => _services.add(ServiceDraft())),
                  onRemove: (index) {
                    setState(() => _services.removeAt(index).dispose());
                  },
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: const TextStyle(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                PrimaryPillButton(
                  label: _saving ? 'Espera...' : 'Enviar a revisión',
                  onPressed: _saving ? null : _save,
                ),
                const SizedBox(height: 16),
                DeleteAccountButton(
                  onBeforeDelete: () async {
                    context.read<ClinicsProvider>().forgetRegistration();
                  },
                ),
              ],
            ),
    );
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

  Future<void> _captureGps() async {
    setState(() => _locating = true);
    try {
      final fix = await readCurrentGps();
      if (!mounted) {
        return;
      }
      setState(() {
        _latitude = fix.latitude;
        _longitude = fix.longitude;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error is StateError
                ? error.message
                : 'No se pudo obtener la ubicación GPS.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _locating = false);
      }
    }
  }

  Future<void> _addClinicPhotos() async {
    if (_photos.length >= maxClinicPhotos) {
      return;
    }
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
    final remaining = maxClinicPhotos - _photos.length;
    if (source == ImageSource.gallery) {
      final picked = await ImagePicker().pickMultiImage(
        imageQuality: 75,
        maxWidth: 1600,
      );
      if (picked.isEmpty || !mounted) {
        return;
      }
      final added = <ClinicPhotoDraft>[];
      for (final file in picked.take(remaining)) {
        added.add(
          ClinicPhotoDraft(file: file, bytes: await file.readAsBytes()),
        );
      }
      if (!mounted) {
        return;
      }
      setState(() => _photos.addAll(added));
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
      _photos.add(ClinicPhotoDraft(file: picked, bytes: bytes));
    });
  }

  Future<void> _save() async {
    final auth = context.read<AuthProvider>();
    final name = _nameController.text.trim();
    final address = _addressController.text.trim();
    if (name.isEmpty || address.isEmpty) {
      setState(() => _error = 'Escribe el nombre y la dirección de la clínica.');
      return;
    }
    if (_phoneController.text.replaceAll(RegExp(r'\D'), '').length < 8) {
      setState(
        () => _error =
            'Escribe un teléfono con código de país, por ejemplo 18095551234.',
      );
      return;
    }
    if (_photos.isEmpty) {
      setState(() => _error = 'Sube al menos una foto de la clínica.');
      return;
    }
    final services = _services
        .map((item) => item.toService())
        .where((item) => item.name.isNotEmpty)
        .toList();
    if (services.isEmpty) {
      setState(() => _error = 'Agrega al menos un servicio.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final clinics = context.read<ClinicsProvider>();
      final urls = <String>[];
      for (var i = 0; i < _photos.length; i++) {
        final photo = _photos[i];
        if (photo.file != null) {
          urls.add(
            await clinics.uploadImage(
              uid: auth.uid,
              name: 'photo_$i',
              file: photo.file!,
            ),
          );
        } else if (photo.url != null && photo.url!.trim().isNotEmpty) {
          urls.add(photo.url!.trim());
        }
      }
      final profile = Clinic(
        id: auth.uid,
        name: name,
        city: _city,
        address: address,
        photoUrl: urls.isNotEmpty ? urls.first : defaultClinicPhoto,
        photoUrls: urls,
        rating: 5,
        country: _country,
        department: _department,
        province: _province,
        phone: _phoneController.text.trim(),
        about: _aboutController.text.trim(),
        services: services,
        latitude: _latitude,
        longitude: _longitude,
        published: false,
        reviewStatus: DoctorReviewStatus.pending,
        submittedAt: DateTime.now(),
      );
      await clinics.saveProfile(profile);
      if (!mounted) {
        return;
      }
      setState(() {
        _photos
          ..clear()
          ..addAll(urls.map((url) => ClinicPhotoDraft(url: url)));
        _reviewStatus = DoctorReviewStatus.pending;
        _rejectionReason = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Solicitud enviada. Un administrador verificará la clínica antes de publicarla.',
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

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.status, this.rejectionReason});

  final DoctorReviewStatus status;
  final String? rejectionReason;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final (Color color, String text) = switch (status) {
      DoctorReviewStatus.draft => (
        colors.muted,
        'Tu clínica aún no es visible. Complétala y envíala a revisión.',
      ),
      DoctorReviewStatus.pending => (
        const Color(0xFFE8A838),
        'Tu clínica está en revisión. Te avisaremos cuando un administrador la verifique.',
      ),
      DoctorReviewStatus.approved => (
        AppColors.primary,
        'Tu clínica está publicada. Si cambias datos, volverá a revisión.',
      ),
      DoctorReviewStatus.rejected => (
        AppColors.danger,
        rejectionReason?.trim().isNotEmpty == true
            ? 'Rechazada: $rejectionReason'
            : 'Tu clínica fue rechazada. Corrige los datos y vuelve a enviarla.',
      ),
    };

    return Material(
      color: color.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Text(
          text,
          style: TextStyle(
            color: color,
            height: 1.35,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
