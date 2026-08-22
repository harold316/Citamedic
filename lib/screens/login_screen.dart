import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../data/locations.dart';
import '../data/mock_data.dart';
import '../models/clinic.dart';
import '../models/clinic_photo_draft.dart';
import '../models/doctor.dart';
import '../models/doctor_review_status.dart';
import '../models/medical_service.dart';
import '../models/user_role.dart';
import '../providers/auth_provider.dart';
import '../providers/clinics_provider.dart';
import '../providers/doctors_provider.dart';
import '../theme/app_theme.dart';
import '../utils/gps.dart';
import '../utils/maps.dart';
import '../widgets/clinic_photo_grid.dart';
import '../widgets/doctor_medical_card.dart';
import '../widgets/google_logo.dart';
import '../widgets/gps_capture_tile.dart';
import '../widgets/location_selectors.dart';
import '../widgets/primary_pill_button.dart';
import '../widgets/service_editor_list.dart';
import '../widgets/specialty_category_dropdown.dart';
import '../widgets/theme_toggle_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _credentialsController = TextEditingController();
  final _hospitalController = TextEditingController();
  final _phoneController = TextEditingController();
  final _aboutController = TextEditingController();
  bool _registerMode = false;
  bool _obscurePassword = true;
  bool _loading = false;
  UserRole _role = UserRole.patient;
  String _specialty = defaultSpecialty;
  String? _error;
  XFile? _photoFile;
  Uint8List? _photoBytes;
  final _clinicPhotos = <ClinicPhotoDraft>[];
  final _clinicServices = <ServiceDraft>[];
  String _clinicCountry = defaultCountry;
  String _clinicDepartment = defaultDepartment;
  String _clinicProvince = defaultProvince;
  String _clinicCity = defaultCity;
  double? _clinicLatitude;
  double? _clinicLongitude;
  bool _clinicLocating = false;

  @override
  void initState() {
    super.initState();
    _clinicServices.add(ServiceDraft());
    for (final controller in [
      _nameController,
      _credentialsController,
      _hospitalController,
    ]) {
      controller.addListener(() {
        if (_registerMode &&
            (_role == UserRole.doctor || _role == UserRole.clinic) &&
            mounted) {
          setState(() {});
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _credentialsController.dispose();
    _hospitalController.dispose();
    _phoneController.dispose();
    _aboutController.dispose();
    for (final service in _clinicServices) {
      service.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 36, 24, 32),
          children: [
            const Align(
              alignment: Alignment.centerRight,
              child: ThemeToggleButton(),
            ),
            Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 40),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'CitaMedic',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppColors.of(context).text,
              ),
            ),
            Text(
              _headline,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.of(context).muted),
            ),
            if (!auth.isReady) ...[
              const SizedBox(height: 16),
              const Text(
                'Firebase no está listo. Reinicia la app en un emulador o celular Android.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.danger,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 28),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ..._accountFields(auth),
                if (_registerMode && _role == UserRole.doctor) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Perfil profesional',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: AppColors.of(context).text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Estos datos son los que verán los pacientes.',
                    style: TextStyle(color: AppColors.of(context).muted),
                  ),
                  const SizedBox(height: 16),
                  ..._doctorFields,
                ],
                if (_registerMode && _role == UserRole.clinic) ...[
                  const SizedBox(height: 24),
                  Text(
                    'Datos de la clínica',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                      color: AppColors.of(context).text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Los pacientes verán este centro en la lista de clínicas.',
                    style: TextStyle(color: AppColors.of(context).muted),
                  ),
                  const SizedBox(height: 16),
                  ..._clinicFields,
                ],
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.danger,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 28),
            if (!_hidePrimaryButton)
              PrimaryPillButton(
                label: _loading ? 'Espera...' : _buttonLabel,
                onPressed: _loading ? null : _submit,
              ),
            if (!_registerMode || _role == UserRole.patient) ...[
              if (_registerMode && _role == UserRole.patient) ...[
                _GoogleSignInButton(
                  loading: _loading,
                  onPressed: _signInWithGoogle,
                ),
              ] else if (!_registerMode) ...[
                const SizedBox(height: 12),
                _GoogleSignInButton(
                  loading: _loading,
                  onPressed: _signInWithGoogle,
                ),
                const SizedBox(height: 12),
                SecondaryPillButton(
                  label: _loading ? 'Espera...' : 'Continuar como invitado',
                  onPressed: _loading ? null : _continueAsGuest,
                ),
                const SizedBox(height: 8),
                Text(
                  'Podrás ver médicos y especialidades, sin agendar citas.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.of(context).muted,
                    fontSize: 13,
                  ),
                ),
              ],
            ],
            if (!_registerMode)
              TextButton(
                onPressed: _loading ? null : _resetPassword,
                child: const Text('Olvidé mi contraseña'),
              ),
            TextButton(
              onPressed: _loading
                  ? null
                  : () => setState(() {
                      _registerMode = !_registerMode;
                      _error = null;
                    }),
              child: Text(
                _registerMode
                    ? '¿Ya tienes cuenta? Inicia sesión'
                    : '¿No tienes cuenta? Regístrate',
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _headline {
    if (_registerMode && _role == UserRole.doctor) {
      return 'Completa tu cuenta y tu perfil profesional. Eso es lo que verán los pacientes.';
    }
    if (_registerMode && _role == UserRole.clinic) {
      return 'Registra tu clínica o centro médico. Un administrador la revisará antes de publicarla.';
    }
    if (_registerMode) {
      return 'Elige si eres paciente, médico o clínica. Los pacientes se registran con Google.';
    }
    return 'Inicia sesión para continuar.';
  }

  String get _buttonLabel {
    if (!_registerMode) {
      return 'Iniciar sesión';
    }
    if (_role == UserRole.doctor) {
      return 'Crear cuenta y publicar perfil';
    }
    if (_role == UserRole.clinic) {
      return 'Crear cuenta y registrar clínica';
    }
    return 'Crear cuenta';
  }

  bool get _hidePrimaryButton =>
      _registerMode && _role == UserRole.patient;

  List<Widget> _accountFields(AuthProvider auth) {
    return [
      if (_registerMode) ...[
        Text(
          'Tipo de cuenta',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: AppColors.of(context).text,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _RoleCard(
                role: UserRole.patient,
                selected: _role == UserRole.patient,
                icon: Icons.person_outline,
                subtitle: 'Regístrate con Google',
                onTap: () => setState(() => _role = UserRole.patient),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _RoleCard(
                role: UserRole.doctor,
                selected: _role == UserRole.doctor,
                icon: Icons.medical_services_outlined,
                subtitle: 'Publica tu perfil profesional',
                onTap: () => setState(() => _role = UserRole.doctor),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _RoleCard(
          role: UserRole.clinic,
          selected: _role == UserRole.clinic,
          icon: Icons.apartment_outlined,
          subtitle: 'Publica tu centro médico',
          onTap: () => setState(() => _role = UserRole.clinic),
        ),
        const SizedBox(height: 16),
        if (_role == UserRole.patient)
          Text(
            'Los pacientes crean su cuenta con Google. Así pueden agendar citas y ver su historial.',
            style: TextStyle(color: AppColors.of(context).muted),
          )
        else ...[
          TextField(
            key: const ValueKey('register-name'),
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: InputDecoration(
              labelText: _role == UserRole.clinic
                  ? 'Nombre de la clínica'
                  : 'Nombre',
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
      if (!_registerMode ||
          _role == UserRole.doctor ||
          _role == UserRole.clinic) ...[
        TextField(
          key: const ValueKey('register-email'),
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          autocorrect: false,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.email],
          decoration: const InputDecoration(labelText: 'Correo'),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const ValueKey('register-password'),
          controller: _passwordController,
          obscureText: _obscurePassword,
          textInputAction: _registerMode
              ? TextInputAction.next
              : TextInputAction.done,
          autofillHints: const [AutofillHints.password],
          onSubmitted: (_) {
            if (!_registerMode && !_loading) {
              _submit();
            }
          },
          decoration: InputDecoration(
            labelText: 'Contraseña',
            suffixIcon: IconButton(
              onPressed: () {
                setState(() => _obscurePassword = !_obscurePassword);
              },
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
        if (_registerMode) ...[
          const SizedBox(height: 12),
          TextField(
            key: const ValueKey('register-confirm'),
            controller: _confirmController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) {
              if (!_loading) {
                _submit();
              }
            },
            decoration: const InputDecoration(labelText: 'Confirmar contraseña'),
          ),
        ],
      ],
    ];
  }

  List<Widget> get _doctorFields {
    return [
      DoctorMedicalCard(
        name: _nameController.text,
        specialty: _specialty,
        credentials: _credentialsController.text,
        hospital: _hospitalController.text,
        photoBytes: _photoBytes,
      ),
      const SizedBox(height: 16),
      _UploadTile(
        label: 'Foto de perfil',
        icon: Icons.photo_camera_outlined,
        filled: _photoBytes != null,
        onTap: _pickImage,
      ),
      const SizedBox(height: 16),
      SpecialtyCategoryDropdown(
        value: _specialty,
        onChanged: (value) => setState(() => _specialty = value),
      ),
      const SizedBox(height: 12),
      TextField(
        key: const ValueKey('register-credentials'),
        controller: _credentialsController,
        decoration: const InputDecoration(labelText: 'Matrícula o credenciales'),
      ),
      const SizedBox(height: 12),
      TextField(
        key: const ValueKey('register-hospital'),
        controller: _hospitalController,
        decoration: const InputDecoration(labelText: 'Clínica u hospital'),
      ),
      const SizedBox(height: 12),
      TextField(
        key: const ValueKey('register-phone'),
        controller: _phoneController,
        keyboardType: TextInputType.phone,
        decoration: const InputDecoration(
          labelText: 'WhatsApp',
          hintText: 'Ej. 18095551234',
          helperText: 'Incluye código de país. Los pacientes te escribirán aquí.',
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        key: const ValueKey('register-about'),
        controller: _aboutController,
        maxLines: 3,
        decoration: const InputDecoration(
          labelText: 'Acerca de ti',
          alignLabelWithHint: true,
        ),
      ),
    ];
  }

  List<Widget> get _clinicFields {
    return [
      ClinicPhotoGrid(
        photos: _clinicPhotos,
        onAdd: _addClinicPhotos,
        onRemove: (index) {
          setState(() => _clinicPhotos.removeAt(index));
        },
      ),
      const SizedBox(height: 16),
      TextField(
        key: const ValueKey('register-clinic-address'),
        controller: _hospitalController,
        decoration: const InputDecoration(labelText: 'Dirección'),
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
        country: _clinicCountry,
        department: _clinicDepartment,
        province: _clinicProvince,
        city: _clinicCity,
        onCountryChanged: _onClinicCountryChanged,
        onDepartmentChanged: _onClinicDepartmentChanged,
        onProvinceChanged: _onClinicProvinceChanged,
        onCityChanged: (value) => setState(() => _clinicCity = value),
      ),
      const SizedBox(height: 12),
      GpsCaptureTile(
        latitude: _clinicLatitude,
        longitude: _clinicLongitude,
        locating: _clinicLocating,
        onCapture: _captureClinicGps,
        onOpenMap: () {
          openClinicMap(_buildClinicProfile('preview'));
        },
      ),
      const SizedBox(height: 12),
      TextField(
        key: const ValueKey('register-clinic-phone'),
        controller: _phoneController,
        keyboardType: TextInputType.phone,
        decoration: const InputDecoration(
          labelText: 'WhatsApp o teléfono',
          hintText: 'Ej. 18095551234',
        ),
      ),
      const SizedBox(height: 12),
      TextField(
        key: const ValueKey('register-clinic-about'),
        controller: _aboutController,
        maxLines: 3,
        decoration: const InputDecoration(
          labelText: 'Acerca de la clínica',
          alignLabelWithHint: true,
        ),
      ),
      const SizedBox(height: 8),
      ServiceEditorList(
        services: _clinicServices,
        onAdd: () => setState(() => _clinicServices.add(ServiceDraft())),
        onRemove: (index) {
          setState(() => _clinicServices.removeAt(index).dispose());
        },
      ),
    ];
  }

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final name = _nameController.text.trim();

    if (_registerMode && _role == UserRole.patient) {
      await _signInWithGoogle();
      return;
    }

    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Escribe tu correo y contraseña.');
      return;
    }
    if (_registerMode && name.isEmpty) {
      setState(
        () => _error = _role == UserRole.clinic
            ? 'Escribe el nombre de la clínica.'
            : 'Escribe tu nombre.',
      );
      return;
    }
    if (_registerMode && password != _confirmController.text) {
      setState(() => _error = 'Las contraseñas no coinciden.');
      return;
    }
    if (_registerMode && _role == UserRole.doctor) {
      if (_hospitalController.text.trim().isEmpty) {
        setState(() => _error = 'Escribe tu clínica u hospital.');
        return;
      }
      if (_photoFile == null) {
        setState(() => _error = 'Sube tu foto de perfil.');
        return;
      }
      final phone = _phoneController.text.replaceAll(RegExp(r'\D'), '');
      if (phone.length < 8) {
        setState(
          () => _error = 'Escribe tu WhatsApp con código de país, por ejemplo 18095551234.',
        );
        return;
      }
    }
    if (_registerMode && _role == UserRole.clinic) {
      if (_hospitalController.text.trim().isEmpty) {
        setState(() => _error = 'Escribe la dirección de la clínica.');
        return;
      }
      if (_clinicPhotos.isEmpty) {
        setState(() => _error = 'Sube al menos una foto de la clínica.');
        return;
      }
      final phone = _phoneController.text.replaceAll(RegExp(r'\D'), '');
      if (phone.length < 8) {
        setState(
          () => _error =
              'Escribe un teléfono con código de país, por ejemplo 18095551234.',
        );
        return;
      }
      final services = _clinicServices
          .map((item) => item.toService())
          .where((item) => item.name.isNotEmpty)
          .toList();
      if (services.isEmpty) {
        setState(() => _error = 'Agrega al menos un servicio.');
        return;
      }
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (_registerMode) {
        final doctors = context.read<DoctorsProvider>();
        final clinics = context.read<ClinicsProvider>();
        if (_role == UserRole.doctor) {
          doctors.rememberRegistration(
            profile: _buildDoctorProfile('pending'),
            photoBytes: _photoBytes,
            photoFile: _photoFile,
          );
        }
        if (_role == UserRole.clinic) {
          clinics.rememberRegistration(
            profile: _buildClinicProfile('pending'),
            photos: _clinicPhotos,
          );
        }
        await auth.register(
          name: name,
          email: email,
          password: password,
          role: _role,
          afterCreate: _role == UserRole.doctor
              ? (uid) => _publishDoctorCard(uid, doctors)
              : _role == UserRole.clinic
              ? (uid) => _publishClinic(uid, clinics)
              : null,
        );
      } else {
        await auth.signIn(email: email, password: password);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = auth.messageFor(error));
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _continueAsGuest() async {
    final auth = context.read<AuthProvider>();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await auth.signInAsGuest();
    } catch (error) {
      if (mounted) {
        setState(() => _error = auth.messageFor(error));
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    final auth = context.read<AuthProvider>();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await auth.signInWithGoogle();
    } catch (error) {
      if (mounted) {
        setState(() => _error = auth.messageFor(error));
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Doctor _buildDoctorProfile(String uid) {
    return Doctor(
      id: uid,
      name: _nameController.text.trim(),
      credentials: _credentialsController.text.trim(),
      specialty: _specialty,
      photoUrl: defaultDoctorPhoto,
      rating: 5,
      reviewCount: 0,
      yearsExperience: 1,
      patientsCount: 0,
      workingHours: 'Lun a Vie, 9:00 - 18:00',
      about: _aboutController.text.trim(),
      hospital: _hospitalController.text.trim(),
      phone: _phoneController.text.trim(),
      city: defaultCity,
      published: false,
      reviewStatus: DoctorReviewStatus.pending,
      submittedAt: DateTime.now(),
      services: const [
        MedicalService(
          id: 'consulta',
          name: 'Consulta',
          price: 1500,
          durationMinutes: 30,
        ),
      ],
    );
  }

  Future<void> _publishDoctorCard(String uid, DoctorsProvider doctors) async {
    var profile =
        (doctors.registrationDraft ?? _buildDoctorProfile(uid)).withId(uid);
    doctors.rememberRegistration(
      profile: profile,
      photoBytes: doctors.registrationPhotoBytes ?? _photoBytes,
      photoFile: doctors.registrationPhotoFile ?? _photoFile,
    );
    final photoFile = doctors.registrationPhotoFile ?? _photoFile;
    if (photoFile != null) {
      final photoUrl = await doctors.uploadImage(
        uid: uid,
        name: 'photo',
        file: photoFile,
      );
      profile = profile.copyWith(photoUrl: photoUrl);
      doctors.rememberRegistration(
        profile: profile,
        photoBytes: doctors.registrationPhotoBytes ?? _photoBytes,
        photoFile: photoFile,
      );
    }
    await doctors.saveProfile(profile);
  }

  Clinic _buildClinicProfile(String uid) {
    final services = _clinicServices
        .map((item) => item.toService())
        .where((item) => item.name.isNotEmpty)
        .toList();
    return Clinic(
      id: uid,
      name: _nameController.text.trim(),
      city: _clinicCity,
      address: _hospitalController.text.trim(),
      photoUrl: defaultClinicPhoto,
      rating: 5,
      country: _clinicCountry,
      department: _clinicDepartment,
      province: _clinicProvince,
      phone: _phoneController.text.trim(),
      about: _aboutController.text.trim(),
      services: services,
      latitude: _clinicLatitude,
      longitude: _clinicLongitude,
      published: false,
      reviewStatus: DoctorReviewStatus.pending,
      submittedAt: DateTime.now(),
    );
  }

  Future<void> _publishClinic(String uid, ClinicsProvider clinics) async {
    var profile =
        (clinics.registrationDraft ?? _buildClinicProfile(uid)).withId(uid);
    final photos = clinics.registrationPhotos.isNotEmpty
        ? clinics.registrationPhotos
        : _clinicPhotos;
    clinics.rememberRegistration(profile: profile, photos: photos);
    final urls = <String>[];
    for (var i = 0; i < photos.length; i++) {
      final photo = photos[i];
      if (photo.file != null) {
        urls.add(
          await clinics.uploadImage(
            uid: uid,
            name: 'photo_$i',
            file: photo.file!,
          ),
        );
      } else if (photo.url != null && photo.url!.trim().isNotEmpty) {
        urls.add(photo.url!.trim());
      }
    }
    profile = profile.copyWith(
      photoUrl: urls.isNotEmpty ? urls.first : defaultClinicPhoto,
      photoUrls: urls,
    );
    clinics.rememberRegistration(profile: profile, photos: photos);
    await clinics.saveProfile(profile);
  }

  Future<void> _addClinicPhotos() async {
    if (_clinicPhotos.length >= maxClinicPhotos) {
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
    final remaining = maxClinicPhotos - _clinicPhotos.length;
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
      setState(() => _clinicPhotos.addAll(added));
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
      _clinicPhotos.add(ClinicPhotoDraft(file: picked, bytes: bytes));
    });
  }

  void _onClinicCountryChanged(String value) {
    final department = catalogDepartments(value).first;
    final province = catalogProvinces(value, department).first;
    setState(() {
      _clinicCountry = value;
      _clinicDepartment = department;
      _clinicProvince = province;
      _clinicCity = catalogCities(value, department, province).first;
    });
  }

  void _onClinicDepartmentChanged(String value) {
    final province = catalogProvinces(_clinicCountry, value).first;
    setState(() {
      _clinicDepartment = value;
      _clinicProvince = province;
      _clinicCity = catalogCities(_clinicCountry, value, province).first;
    });
  }

  void _onClinicProvinceChanged(String value) {
    setState(() {
      _clinicProvince = value;
      _clinicCity = catalogCities(_clinicCountry, _clinicDepartment, value).first;
    });
  }

  Future<void> _captureClinicGps() async {
    setState(() => _clinicLocating = true);
    try {
      final fix = await readCurrentGps();
      if (!mounted) {
        return;
      }
      setState(() {
        _clinicLatitude = fix.latitude;
        _clinicLongitude = fix.longitude;
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
        setState(() => _clinicLocating = false);
      }
    }
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

  Future<void> _resetPassword() async {
    final auth = context.read<AuthProvider>();
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(
        () => _error = 'Escribe tu correo para enviarte el restablecimiento.',
      );
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await auth.sendPasswordReset(email);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Te enviamos un correo para restablecer la contraseña.'),
        ),
      );
    } catch (error) {
      if (mounted) {
        setState(() => _error = auth.messageFor(error));
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }
}

class _GoogleSignInButton extends StatelessWidget {
  const _GoogleSignInButton({
    required this.loading,
    required this.onPressed,
  });

  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: loading ? null : onPressed,
        icon: const GoogleLogo(size: 22),
        label: Text(loading ? 'Espera...' : 'Continuar con Google'),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.role,
    required this.selected,
    required this.icon,
    required this.subtitle,
    required this.onTap,
  });

  final UserRole role;
  final bool selected;
  final IconData icon;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Material(
      color: selected ? colors.primarySoft : colors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppColors.primary : colors.border,
              width: selected ? 1.8 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: selected ? AppColors.primary : colors.muted),
              const SizedBox(height: 8),
              Text(
                role.label,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: selected ? AppColors.primary : colors.text,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.muted, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UploadTile extends StatelessWidget {
  const _UploadTile({
    required this.label,
    required this.icon,
    required this.filled,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Material(
      color: filled ? colors.primarySoft : colors.surface,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 10),
          child: Column(
            children: [
              Icon(filled ? Icons.check_circle : icon, color: AppColors.primary),
              const SizedBox(height: 8),
              Text(
                filled ? '$label lista' : label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: colors.text,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
