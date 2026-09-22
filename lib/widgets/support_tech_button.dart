import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../utils/whatsapp.dart';

class SupportTechButton extends StatelessWidget {
  const SupportTechButton({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: openSupportWhatsApp,
        icon: const Icon(Icons.support_agent, color: AppColors.whatsapp),
        label: const Text('Soporte técnico'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.whatsapp,
          side: const BorderSide(color: AppColors.whatsapp),
        ),
      ),
    );
  }
}

class SupportTechIconButton extends StatelessWidget {
  const SupportTechIconButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Soporte técnico',
      visualDensity: VisualDensity.compact,
      style: IconButton.styleFrom(
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        minimumSize: const Size(40, 40),
        padding: const EdgeInsets.all(6),
      ),
      onPressed: openSupportWhatsApp,
      icon: const Icon(Icons.support_agent, color: AppColors.whatsapp),
    );
  }
}
