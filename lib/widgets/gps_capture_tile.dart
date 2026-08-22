import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class GpsCaptureTile extends StatelessWidget {
  const GpsCaptureTile({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.locating,
    required this.onCapture,
    this.onOpenMap,
  });

  final double? latitude;
  final double? longitude;
  final bool locating;
  final VoidCallback onCapture;
  final VoidCallback? onOpenMap;

  bool get _hasFix => latitude != null && longitude != null;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_hasFix)
          Text(
            'GPS: ${latitude!.toStringAsFixed(5)}, ${longitude!.toStringAsFixed(5)}',
            style: TextStyle(color: colors.muted, fontSize: 12),
          )
        else
          Text(
            'Comparte tu ubicación GPS para que los pacientes sepan cómo llegar.',
            style: TextStyle(color: colors.muted, fontSize: 13),
          ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: locating ? null : onCapture,
          icon: locating
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.my_location, color: AppColors.location),
          label: Text(
            locating
                ? 'Obteniendo ubicación...'
                : _hasFix
                ? 'Actualizar ubicación GPS'
                : 'Usar mi ubicación GPS',
          ),
        ),
        if (_hasFix && onOpenMap != null) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: onOpenMap,
            icon: const Icon(Icons.map_outlined, color: AppColors.location),
            label: const Text('Ver en el mapa'),
          ),
        ],
      ],
    );
  }
}
