import 'package:flutter/material.dart';

import '../models/doctor.dart';
import '../theme/app_theme.dart';

class DoctorAvatar extends StatelessWidget {
  const DoctorAvatar({
    super.key,
    required this.doctor,
    this.size = 48,
  });

  final Doctor doctor;
  final double size;

  String get _initial {
    final name = doctor.name.trim();
    if (name.isEmpty) {
      return 'M';
    }
    final parts = name.split(' ').where((part) => part.isNotEmpty);
    return (parts.isEmpty ? name : parts.last)[0].toUpperCase();
  }

  bool get _hasPhoto {
    final url = doctor.photoUrl.trim();
    return url.isNotEmpty && url != defaultDoctorPhoto;
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final letter = CircleAvatar(
      radius: size / 2,
      backgroundColor: colors.primarySoft,
      child: Text(
        _initial,
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );

    if (!_hasPhoto) {
      return letter;
    }

    return ClipOval(
      child: Image.network(
        doctor.photoUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => letter,
        loadingBuilder: (context, child, progress) {
          if (progress == null) {
            return child;
          }
          return CircleAvatar(
            radius: size / 2,
            backgroundColor: colors.primarySoft,
            child: const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
      ),
    );
  }
}
