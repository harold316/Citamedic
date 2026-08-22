import 'package:flutter/material.dart';

import '../models/medical_service.dart';
import '../theme/app_theme.dart';

class ServiceDraft {
  ServiceDraft({
    String? id,
    String name = 'Consulta',
    String price = '1500',
    String duration = '30',
  }) : id = id ?? DateTime.now().microsecondsSinceEpoch.toString(),
       nameController = TextEditingController(text: name),
       priceController = TextEditingController(text: price),
       durationController = TextEditingController(text: duration);

  factory ServiceDraft.fromService(MedicalService service) {
    return ServiceDraft(
      id: service.id,
      name: service.name,
      price: service.price.toStringAsFixed(0),
      duration: '${service.durationMinutes}',
    );
  }

  final String id;
  final TextEditingController nameController;
  final TextEditingController priceController;
  final TextEditingController durationController;

  MedicalService toService() {
    return MedicalService(
      id: id,
      name: nameController.text.trim(),
      price: double.tryParse(priceController.text.trim()) ?? 0,
      durationMinutes: int.tryParse(durationController.text.trim()) ?? 30,
    );
  }

  void dispose() {
    nameController.dispose();
    priceController.dispose();
    durationController.dispose();
  }
}

class ServiceEditorList extends StatelessWidget {
  const ServiceEditorList({
    super.key,
    required this.services,
    required this.onAdd,
    required this.onRemove,
  });

  final List<ServiceDraft> services;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = AppColors.of(context);
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Servicios',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: colors.text,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add, color: AppColors.primary),
              label: const Text('Agregar'),
            ),
          ],
        ),
        for (final entry in services.asMap().entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 8, 14),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: entry.value.nameController,
                            decoration: const InputDecoration(
                              labelText: 'Servicio',
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: services.length == 1
                              ? null
                              : () => onRemove(entry.key),
                          icon: const Icon(
                            Icons.delete_outline,
                            color: AppColors.danger,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: entry.value.priceController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Precio (Bs)',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: entry.value.durationController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Minutos',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
