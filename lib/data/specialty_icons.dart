import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

const specialtyIcons = {
  'Dermatología': Icons.spa_outlined,
  'Cardiología': Icons.favorite_outline,
  'Pediatría': Icons.child_care_outlined,
  'Neonatología': Icons.child_friendly_outlined,
  'Ginecología y obstetricia': Icons.pregnant_woman_outlined,
  'Otorrinolaringología': Icons.hearing_outlined,
  'Urología': Icons.water_drop_outlined,
  'Nefrología': Icons.bloodtype_outlined,
  'Cirugía general': Icons.healing_outlined,
  'Traumatología y ortopedia': Icons.personal_injury_outlined,
  'Medicina interna': Icons.medical_information_outlined,
  'Salud pública': Icons.public_outlined,
  'Medicina Crítica y Terapia Intensiva': Icons.emergency_outlined,
  'Odontología': Icons.medical_services_outlined,
  'Medicina general': Icons.local_hospital_outlined,
  'Enfermería': Icons.health_and_safety_outlined,
  'Ecografía': Icons.monitor_heart_outlined,
  'Rayos X': Icons.scanner,
  'Laboratorio': Icons.science_outlined,
  'Nutrición': Icons.restaurant_outlined,
  'Especialidades': Icons.grid_view_rounded,
  'Clínicas': Icons.apartment_outlined,
  'Servicios médicos': Icons.biotech_outlined,
};

const specialtyIconColors = {
  'Dermatología': Color(0xFFE07A9A),
  'Cardiología': Color(0xFFE05A5A),
  'Pediatría': Color(0xFF3B82F6),
  'Neonatología': Color(0xFF06B6D4),
  'Ginecología y obstetricia': Color(0xFFEC4899),
  'Otorrinolaringología': Color(0xFF0EA5E9),
  'Urología': Color(0xFF2563EB),
  'Nefrología': Color(0xFF0F766E),
  'Cirugía general': Color(0xFF78716C),
  'Traumatología y ortopedia': Color(0xFFD97706),
  'Medicina interna': Color(0xFF4F46E5),
  'Salud pública': Color(0xFF16A34A),
  'Medicina Crítica y Terapia Intensiva': Color(0xFFDC2626),
  'Odontología': Color(0xFF14B8A6),
  'Medicina general': AppColors.primary,
  'Enfermería': Color(0xFF22A06B),
  'Ecografía': Color(0xFF6366F1),
  'Rayos X': Color(0xFF64748B),
  'Laboratorio': Color(0xFF8B5CF6),
  'Nutrición': Color(0xFFF59E0B),
  'Especialidades': Color(0xFF6366F1),
  'Especialidades médicas': Color(0xFF6366F1),
  'Clínicas': Color(0xFF2563EB),
  'Servicios médicos': Color(0xFF0EA5E9),
};

Color iconColorFor(String name) {
  return specialtyIconColors[name] ?? AppColors.primary;
}
