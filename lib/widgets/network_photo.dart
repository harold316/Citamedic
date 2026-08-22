import 'package:flutter/material.dart';
import 'package:insta_image_viewer/insta_image_viewer.dart';

import '../theme/app_theme.dart';

class NetworkPhoto extends StatelessWidget {
  const NetworkPhoto({
    super.key,
    required this.url,
    this.borderRadius,
    this.fit = BoxFit.cover,
    this.viewable = false,
  });

  final String url;
  final BorderRadius? borderRadius;
  final BoxFit fit;
  final bool viewable;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    Widget image = Image.network(
      url,
      fit: fit,
      errorBuilder: (_, _, _) => Container(
        color: colors.primarySoft,
        alignment: Alignment.center,
        child: const Icon(Icons.person, color: AppColors.primary, size: 48),
      ),
      loadingBuilder: (context, child, progress) {
        if (progress == null) {
          return child;
        }
        return Container(
          color: colors.primarySoft,
          alignment: Alignment.center,
          child: const CircularProgressIndicator(strokeWidth: 2),
        );
      },
    );

    if (borderRadius != null) {
      image = ClipRRect(borderRadius: borderRadius!, child: image);
    }

    if (viewable) {
      image = InstaImageViewer(
        imageUrl: url,
        backgroundColor: Colors.black,
        child: image,
      );
    }

    return image;
  }
}
