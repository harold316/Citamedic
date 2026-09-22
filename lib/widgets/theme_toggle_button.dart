import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';

class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final (icon, tooltip, color) = switch (theme.mode) {
      ThemeMode.system => (Icons.brightness_auto, 'Tema: sistema', AppColors.primary),
      ThemeMode.light => (Icons.light_mode, 'Tema: claro', const Color(0xFFF59E0B)),
      ThemeMode.dark => (Icons.dark_mode, 'Tema: oscuro', const Color(0xFF6366F1)),
    };

    return IconButton(
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
      style: IconButton.styleFrom(
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        minimumSize: const Size(40, 40),
        padding: const EdgeInsets.all(6),
      ),
      onPressed: () => theme.cycle(MediaQuery.platformBrightnessOf(context)),
      icon: Icon(icon, color: color),
    );
  }
}
