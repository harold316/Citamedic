import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/appointment.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class AppointmentCard extends StatelessWidget {
  const AppointmentCard({
    super.key,
    required this.appointment,
    required this.title,
    this.subtitle,
    this.leading,
    this.onTap,
    this.onDelete,
    this.onAccept,
    this.onReschedule,
  });

  final Appointment appointment;
  final String title;
  final String? subtitle;
  final Widget? leading;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onAccept;
  final VoidCallback? onReschedule;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final dateLabel = DateFormat("EEE d MMM, HH:mm", 'es').format(
      appointment.dateTime,
    );
    final showAccept = onAccept != null && appointment.isPending;
    final showReschedule = onReschedule != null;

    return Material(
      color: colors.surface,
      elevation: 2,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IgnorePointer(
                    child: leading ??
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: colors.primarySoft,
                          child: Text(
                            title.isEmpty ? 'P' : title[0].toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: colors.text,
                          ),
                        ),
                        Text(
                          subtitle ?? appointment.serviceName,
                          style: TextStyle(color: colors.muted),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          dateLabel,
                          style: TextStyle(
                            color: appointment.isPast && !appointment.isPending
                                ? colors.muted
                                : AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                        if (appointment.hasPatientMessage) ...[
                          const SizedBox(height: 6),
                          Text(
                            appointment.patientMessage,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.text,
                              fontSize: 12,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        formatPrice(appointment.price),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: colors.text,
                        ),
                      ),
                      Text(
                        appointment.statusLabel,
                        style: TextStyle(
                          color: _statusColor(colors),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (onDelete != null)
                        IconButton(
                          tooltip: 'Eliminar cita',
                          onPressed: onDelete,
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
                          ),
                          style: IconButton.styleFrom(
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          icon: const Icon(
                            Icons.delete_outline,
                            color: AppColors.danger,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              if (showAccept || showReschedule) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (showAccept)
                      Expanded(
                        child: ElevatedButton(
                          onPressed: onAccept,
                          child: const Text('Aceptar'),
                        ),
                      ),
                    if (showAccept && showReschedule) const SizedBox(width: 8),
                    if (showReschedule)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onReschedule,
                          child: const Text('Cambiar horario'),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(AppColors colors) {
    if (appointment.isPast && !appointment.isPending) {
      return colors.muted;
    }
    switch (appointment.status) {
      case AppointmentStatus.pending:
        return AppColors.accent;
      case AppointmentStatus.accepted:
        return AppColors.primary;
      case AppointmentStatus.rescheduled:
        return AppColors.location;
    }
  }
}
