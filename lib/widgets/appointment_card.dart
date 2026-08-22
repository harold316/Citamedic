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
  });

  final Appointment appointment;
  final String title;
  final String? subtitle;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final dateLabel = DateFormat("EEE d MMM, HH:mm", 'es').format(
      appointment.dateTime,
    );
    final isPast = appointment.dateTime.isBefore(DateTime.now());

    return Material(
      color: colors.surface,
      elevation: 2,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            leading ??
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
                      color: isPast ? colors.muted : AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
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
                  isPast ? 'Pasada' : 'Agendada',
                  style: TextStyle(
                    color: isPast ? colors.muted : AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
