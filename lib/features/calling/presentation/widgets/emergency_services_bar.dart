import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/calling_bloc.dart';
import 'sos_trigger_dialog.dart';

class EmergencyServicesBar extends StatelessWidget {
  const EmergencyServicesBar({super.key});

  final List<Map<String, dynamic>> _services = const [
    {'title': 'Police', 'number': '122', 'icon': Icons.local_police_rounded, 'color': Color(0xFF1E88E5)},
    {'title': 'Ambulance', 'number': '123', 'icon': Icons.medical_services_rounded, 'color': Color(0xFFE53935)},
    {'title': 'Fire', 'number': '180', 'icon': Icons.local_fire_department_rounded, 'color': Color(0xFFFB8C00)},
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: 44,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _services.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            return ActionChip(
              avatar: const Icon(Icons.sos_rounded, size: 16, color: Colors.red),
              label: const Text(
                'Family SOS (طوارئ العائلة)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              backgroundColor: Colors.red.withValues(alpha: 0.12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              onPressed: () => SosTriggerDialog.show(context),
            );
          }

          final s = _services[index - 1];
          final Color btnColor = s['color'] as Color;

          return ActionChip(
            avatar: Icon(s['icon'] as IconData, size: 16, color: btnColor),
            label: Text(
              '${s['title']} (${s['number']})',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            backgroundColor: btnColor.withValues(alpha: 0.12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            onPressed: () {
              context.read<CallingBloc>().add(
                    TriggerDirectCallEvent(
                      phoneNumber: s['number'] as String,
                      contactName: 'Emergency ${s['title']}',
                    ),
                  );
            },
          );
        },
      ),
    );
  }
}
