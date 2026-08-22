import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'network_photo.dart';

class ClinicPhotoGallery extends StatelessWidget {
  const ClinicPhotoGallery({super.key, required this.urls});

  final List<String> urls;

  @override
  Widget build(BuildContext context) {
    if (urls.isEmpty) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      height: 200,
      child: PageView.builder(
        itemCount: urls.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: NetworkPhoto(
              url: urls[index],
              viewable: true,
              borderRadius: BorderRadius.circular(24),
            ),
          );
        },
      ),
    );
  }
}

class ClinicPhotoDots extends StatelessWidget {
  const ClinicPhotoDots({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    if (count <= 1) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Text(
        'Desliza para ver $count fotos',
        style: TextStyle(
          color: AppColors.of(context).muted,
          fontSize: 12,
        ),
      ),
    );
  }
}
