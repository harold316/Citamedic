import 'package:flutter/material.dart';

import '../models/clinic_photo_draft.dart';
import '../theme/app_theme.dart';
import 'network_photo.dart';

const maxClinicPhotos = 8;

class ClinicPhotoGrid extends StatelessWidget {
  const ClinicPhotoGrid({
    super.key,
    required this.photos,
    required this.onAdd,
    required this.onRemove,
  });

  final List<ClinicPhotoDraft> photos;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final canAdd = photos.length < maxClinicPhotos;
    final count = photos.length + (canAdd ? 1 : 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fotos (${photos.length}/$maxClinicPhotos)',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: colors.text,
          ),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: count,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemBuilder: (context, index) {
            if (canAdd && index == photos.length) {
              return Material(
                color: colors.surface,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: onAdd,
                  borderRadius: BorderRadius.circular(16),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo_outlined, color: AppColors.primary),
                      SizedBox(height: 4),
                      Text(
                        'Añadir',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            final photo = photos[index];
            return Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: photo.bytes != null
                      ? Image.memory(photo.bytes!, fit: BoxFit.cover)
                      : NetworkPhoto(
                          url: photo.url ?? '',
                          borderRadius: BorderRadius.circular(16),
                        ),
                ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: Material(
                    color: Colors.black54,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => onRemove(index),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.close, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}
