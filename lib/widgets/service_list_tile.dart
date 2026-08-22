import 'package:flutter/material.dart';

import '../models/medical_service.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

class ServiceListTile extends StatelessWidget {
  const ServiceListTile({
    super.key,
    required this.service,
    required this.onTap,
    this.highlighted = false,
    this.trailingIcon = Icons.north_east,
  });

  final MedicalService service;
  final VoidCallback onTap;
  final bool highlighted;
  final IconData trailingIcon;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    final background = highlighted ? AppColors.primary : colors.surface;
    final titleColor = highlighted ? Colors.white : colors.text;
    final subtitleColor = highlighted ? Colors.white70 : colors.muted;
    final iconBg = highlighted ? Colors.white : AppColors.primary;
    final iconColor = highlighted ? AppColors.primary : Colors.white;

    return Material(
      color: background,
      elevation: highlighted ? 0 : 2,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.name,
                      style: TextStyle(
                        color: titleColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${formatPrice(service.price)} por sesión',
                      style: TextStyle(color: subtitleColor, fontSize: 13),
                    ),
                  ],
                ),
              ),
              CircleAvatar(
                radius: 18,
                backgroundColor: iconBg,
                child: Icon(trailingIcon, color: iconColor, size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
