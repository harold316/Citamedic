import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../models/doctor.dart';
import '../theme/app_theme.dart';
import 'network_photo.dart';

class DoctorMedicalCard extends StatelessWidget {
  const DoctorMedicalCard({
    super.key,
    required this.name,
    required this.specialty,
    required this.credentials,
    required this.hospital,
    this.photoUrl,
    this.photoBytes,
    this.medicalCardUrl,
    this.medicalCardBytes,
  });

  factory DoctorMedicalCard.fromDoctor(Doctor doctor) {
    return DoctorMedicalCard(
      name: doctor.name,
      specialty: doctor.specialty,
      credentials: doctor.credentials,
      hospital: doctor.hospital,
      photoUrl: doctor.photoUrl,
      medicalCardUrl: doctor.medicalCardUrl,
    );
  }

  final String name;
  final String specialty;
  final String credentials;
  final String hospital;
  final String? photoUrl;
  final Uint8List? photoBytes;
  final String? medicalCardUrl;
  final Uint8List? medicalCardBytes;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: SizedBox(
                    width: 88,
                    height: 88,
                    child: _image(
                      context: context,
                      bytes: photoBytes,
                      url: photoUrl,
                      fallback: Icons.person,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.isEmpty ? 'Tu nombre' : name,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: colors.text,
                        ),
                      ),
                      Text(
                        specialty.isEmpty ? 'Especialidad' : specialty,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (credentials.isNotEmpty)
                        Text(
                          credentials,
                          style: TextStyle(color: colors.muted),
                        ),
                      if (hospital.isNotEmpty)
                        Text(
                          hospital,
                          style: TextStyle(color: colors.muted),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (medicalCardBytes != null ||
              (medicalCardUrl != null && medicalCardUrl!.trim().isNotEmpty))
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: SizedBox(
                  height: 160,
                  width: double.infinity,
                  child: _image(
                    context: context,
                    bytes: medicalCardBytes,
                    url: medicalCardUrl,
                    fallback: Icons.badge_outlined,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _image({
    required BuildContext context,
    required IconData fallback,
    Uint8List? bytes,
    String? url,
  }) {
    if (bytes != null) {
      return Image.memory(bytes, fit: BoxFit.cover);
    }
    if (url != null &&
        url.trim().isNotEmpty &&
        url != defaultDoctorPhoto) {
      return NetworkPhoto(url: url, fit: BoxFit.cover);
    }
    return ColoredBox(
      color: AppColors.of(context).primarySoft,
      child: Icon(fallback, color: AppColors.primary, size: 36),
    );
  }
}
