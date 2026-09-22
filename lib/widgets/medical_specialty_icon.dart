import 'package:flutter/material.dart';
import 'package:healthicons_flutter/filled/ambulatory_clinic.dart';
import 'package:healthicons_flutter/filled/baby_0203m.dart';
import 'package:healthicons_flutter/filled/bandaged.dart';
import 'package:healthicons_flutter/filled/biochemistry_laboratory.dart';
import 'package:healthicons_flutter/filled/cancerous_cell_nuclei.dart';
import 'package:healthicons_flutter/filled/cardiology.dart';
import 'package:healthicons_flutter/filled/colon.dart';
import 'package:healthicons_flutter/filled/dental_hygiene.dart';
import 'package:healthicons_flutter/filled/diagnostics.dart';
import 'package:healthicons_flutter/filled/ears_nose_and_throat.dart';
import 'package:healthicons_flutter/filled/endocrinology.dart';
import 'package:healthicons_flutter/filled/gastroenterology.dart';
import 'package:healthicons_flutter/filled/general_surgery.dart';
import 'package:healthicons_flutter/filled/gynecology.dart';
import 'package:healthicons_flutter/filled/hematology.dart';
import 'package:healthicons_flutter/filled/hospital_symbol.dart';
import 'package:healthicons_flutter/filled/intravenous_drip.dart';
import 'package:healthicons_flutter/filled/intensive_care_unit.dart';
import 'package:healthicons_flutter/filled/lungs.dart';
import 'package:healthicons_flutter/filled/mental_health.dart';
import 'package:healthicons_flutter/filled/nephrology.dart';
import 'package:healthicons_flutter/filled/neuro_surgery.dart';
import 'package:healthicons_flutter/filled/neurology.dart';
import 'package:healthicons_flutter/filled/nurse.dart';
import 'package:healthicons_flutter/filled/nutrition.dart';
import 'package:healthicons_flutter/filled/odontology.dart';
import 'package:healthicons_flutter/filled/oncology.dart';
import 'package:healthicons_flutter/filled/pediatric_surgery.dart';
import 'package:healthicons_flutter/filled/pediatrics.dart';
import 'package:healthicons_flutter/filled/physical_therapy.dart';
import 'package:healthicons_flutter/filled/radiology.dart';
import 'package:healthicons_flutter/filled/rheumatology.dart';
import 'package:healthicons_flutter/filled/skin_cancer.dart';
import 'package:healthicons_flutter/filled/sonography.dart';
import 'package:healthicons_flutter/filled/stethoscope.dart';
import 'package:healthicons_flutter/filled/ui_menu_grid.dart';
import 'package:healthicons_flutter/filled/urology.dart';
import 'package:healthicons_flutter/filled/varicose_vein.dart';
import 'package:healthicons_flutter/filled/world_care.dart';
import 'package:healthicons_flutter/filled/xray.dart';

class MedicalSpecialtyIcon extends StatelessWidget {
  const MedicalSpecialtyIcon({
    super.key,
    required this.name,
    this.color,
    this.size = 28,
  });

  final String name;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final paintColor = color ?? IconTheme.of(context).color ?? Colors.black;
    return SizedBox(
      width: size,
      height: size,
      child: healthIconFor(name, color: paintColor, size: size),
    );
  }
}

Widget healthIconFor(String name, {required Color color, required double size}) {
  return switch (name) {
    'Dermatología' => SkinCancer(color: color, width: size, height: size),
    'Cardiología' => Cardiology(color: color, width: size, height: size),
    'Pediatría' => Pediatrics(color: color, width: size, height: size),
    'Neonatología' => Baby0203m(color: color, width: size, height: size),
    'Ginecología y obstetricia' =>
      Gynecology(color: color, width: size, height: size),
    'Otorrinolaringología' =>
      EarsNoseAndThroat(color: color, width: size, height: size),
    'Urología' => Urology(color: color, width: size, height: size),
    'Nefrología' => Nephrology(color: color, width: size, height: size),
    'Cirugía general' =>
      GeneralSurgery(color: color, width: size, height: size),
    'Cirugía pediátrica' =>
      PediatricSurgery(color: color, width: size, height: size),
    'Cirugía maxilofacial' =>
      DentalHygiene(color: color, width: size, height: size),
    'Neurología' => Neurology(color: color, width: size, height: size),
    'Neurocirugía' => NeuroSurgery(color: color, width: size, height: size),
    'Oncología' => Oncology(color: color, width: size, height: size),
    'Cirugía oncológica' =>
      CancerousCellNuclei(color: color, width: size, height: size),
    'Cirugía plástica y reconstructiva' =>
      Bandaged(color: color, width: size, height: size),
    'Anestesiología' =>
      IntravenousDrip(color: color, width: size, height: size),
    'Traumatología y ortopedia' => _BoneIcon(color: color, size: size),
    'Medicina interna' => Stethoscope(color: color, width: size, height: size),
    'Endocrinología' =>
      Endocrinology(color: color, width: size, height: size),
    'Gastroenterología' =>
      Gastroenterology(color: color, width: size, height: size),
    'Neumología' => Lungs(color: color, width: size, height: size),
    'Hematología' => Hematology(color: color, width: size, height: size),
    'Flebología' => VaricoseVein(color: color, width: size, height: size),
    'Reumatología' => Rheumatology(color: color, width: size, height: size),
    'Psiquiatría' => MentalHealth(color: color, width: size, height: size),
    'Salud pública' => WorldCare(color: color, width: size, height: size),
    'Medicina crítica y terapia intensiva' ||
    'Medicina Crítica y Terapia Intensiva' =>
      IntensiveCareUnit(color: color, width: size, height: size),
    'Odontología' => Odontology(color: color, width: size, height: size),
    'Medicina general' =>
      HospitalSymbol(color: color, width: size, height: size),
    'Enfermería' => Nurse(color: color, width: size, height: size),
    'Ecografía' => Sonography(color: color, width: size, height: size),
    'Rayos X' => Xray(color: color, width: size, height: size),
    'Tomografía computarizada' =>
      Radiology(color: color, width: size, height: size),
    'Imagenología' => Diagnostics(color: color, width: size, height: size),
    'Endoscopia' => Colon(color: color, width: size, height: size),
    'Laboratorio' =>
      BiochemistryLaboratory(color: color, width: size, height: size),
    'Fisioterapia y rehabilitación' =>
      PhysicalTherapy(color: color, width: size, height: size),
    'Nutrición' => Nutrition(color: color, width: size, height: size),
    'Especialidades' ||
    'Especialidades médicas' =>
      UiMenuGrid(color: color, width: size, height: size),
    'Clínicas' => AmbulatoryClinic(color: color, width: size, height: size),
    'Servicios médicos' => Diagnostics(color: color, width: size, height: size),
    _ => HospitalSymbol(color: color, width: size, height: size),
  };
}

class _BoneIcon extends StatelessWidget {
  const _BoneIcon({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _BonePainter(color),
    );
  }
}

class _BonePainter extends CustomPainter {
  _BonePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    canvas.save();
    canvas.translate(w * 0.5, h * 0.5);
    canvas.rotate(-0.7);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset.zero,
          width: w * 0.30,
          height: h * 0.58,
        ),
        Radius.circular(w * 0.15),
      ),
      paint,
    );

    final r = w * 0.17;
    final end = h * 0.26;
    canvas.drawCircle(Offset(-w * 0.09, -end), r, paint);
    canvas.drawCircle(Offset(w * 0.09, -end), r, paint);
    canvas.drawCircle(Offset(-w * 0.09, end), r, paint);
    canvas.drawCircle(Offset(w * 0.09, end), r, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BonePainter oldDelegate) =>
      oldDelegate.color != color;
}
