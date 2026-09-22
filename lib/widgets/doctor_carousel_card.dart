import 'package:flutter/material.dart';

import '../models/doctor.dart';
import '../theme/app_theme.dart';
import 'network_photo.dart';

class DoctorCarouselCard extends StatelessWidget {
  const DoctorCarouselCard({
    super.key,
    required this.doctor,
    required this.isFavorite,
    required this.onTap,
    required this.onFavorite,
    this.selected = false,
  });

  final Doctor doctor;
  final bool isFavorite;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 210,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: selected ? AppColors.primary : Colors.transparent,
                    width: 3,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: NetworkPhoto(
                          url: doctor.photoUrl,
                          borderRadius: BorderRadius.circular(28),
                        ),
                      ),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: _HeartButton(
                          isFavorite: isFavorite,
                          onTap: onFavorite,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              doctor.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 18,
                height: 1.2,
                fontWeight: FontWeight.w800,
                color: colors.text,
              ),
            ),
            Text(
              doctor.specialty,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: colors.muted, fontSize: 14),
            ),
            Text(
              '${doctor.yearsExperience} años de experiencia',
              style: TextStyle(color: colors.muted, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeartButton extends StatelessWidget {
  const _HeartButton({required this.isFavorite, required this.onTap});

  final bool isFavorite;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Material(
      color: colors.surface,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            color: isFavorite ? AppColors.danger : AppColors.primary,
            size: 16,
          ),
        ),
      ),
    );
  }
}
