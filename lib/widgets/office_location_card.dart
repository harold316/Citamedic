import 'package:flutter/material.dart';

import '../models/doctor.dart';
import '../theme/app_theme.dart';
import '../utils/maps.dart';
import '../utils/whatsapp.dart';

class OfficeLocationCard extends StatelessWidget {
  const OfficeLocationCard({
    super.key,
    required this.doctor,
    this.onEdit,
  });

  final Doctor doctor;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Consultorio',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: colors.text,
                  ),
                ),
              ),
              if (onEdit != null)
                TextButton(onPressed: onEdit, child: const Text('Editar')),
            ],
          ),
          Text(
            doctor.hasOfficeLocation
                ? doctor.locationLabel
                : 'Aún no hay una ubicación registrada.',
            style: TextStyle(color: colors.muted),
          ),
          Text(doctor.city, style: TextStyle(color: colors.muted)),
          const SizedBox(height: 12),
          if (doctor.hasOfficeLocation)
            OutlinedButton.icon(
              onPressed: () => openDoctorOfficeMap(doctor),
              icon: const Icon(
                Icons.directions_outlined,
                color: AppColors.location,
              ),
              label: const Text('Cómo llegar'),
            )
          else if (onEdit != null)
            OutlinedButton.icon(
              onPressed: onEdit,
              icon: const Icon(
                Icons.add_location_alt_outlined,
                color: AppColors.location,
              ),
              label: const Text('Añadir ubicación'),
            ),
          if (doctor.hasWhatsApp) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => openDoctorWhatsApp(doctor),
              icon: const Icon(Icons.chat, color: AppColors.whatsapp),
              label: const Text('Escribir por WhatsApp'),
            ),
          ],
        ],
      ),
    );
  }
}
