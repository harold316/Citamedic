import 'package:flutter/material.dart';

import '../models/doctor.dart';
import '../theme/app_theme.dart';
import 'network_photo.dart';

class DoctorResultCard extends StatelessWidget {
  const DoctorResultCard({
    super.key,
    required this.doctor,
    required this.onTap,
    this.isFavorite = false,
    this.onFavorite,
  });

  final Doctor doctor;
  final VoidCallback onTap;
  final bool isFavorite;
  final VoidCallback? onFavorite;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Material(
      color: colors.surface,
      elevation: 2,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              SizedBox(
                width: 78,
                height: 78,
                child: NetworkPhoto(
                  url: doctor.photoUrl,
                  borderRadius: BorderRadius.circular(18),
                ),
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
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.star, color: AppColors.star, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${doctor.rating}',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${doctor.yearsExperience} años',
                          style: TextStyle(
                            color: colors.muted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (onFavorite != null)
                IconButton(
                  onPressed: onFavorite,
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? AppColors.danger : AppColors.primary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
