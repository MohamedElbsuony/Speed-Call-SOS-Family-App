import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../contacts/domain/models/contact_model.dart';
import '../../domain/models/speed_dial_key_model.dart';
import '../bloc/speed_dial_bloc.dart';
import '../widgets/sim_selection_sheet.dart';

class SpeedDialManagerScreen extends StatelessWidget {
  const SpeedDialManagerScreen({super.key});

  void _assignContactToKey(BuildContext context, int digit, SpeedDialKeyModel? existing) async {
    final result = await context.push<Map<String, dynamic>>('/contacts?select=true');
    if (result != null && context.mounted) {
      final ContactModel contact = result['contact'] as ContactModel;
      final PhoneEntry phone = result['phone'] as PhoneEntry;

      final simMode = await SimSelectionSheet.show(context, initialSimMode: existing?.simSelectionMode ?? 0) ?? 0;

      final newSpeedDial = SpeedDialKeyModel(
        keyDigit: digit,
        contactId: contact.id,
        contactName: contact.displayName,
        phoneNumber: phone.number,
        phoneLabel: phone.label,
        simSelectionMode: simMode,
      );

      if (context.mounted) {
        context.read<SpeedDialBloc>().add(AssignSpeedDialKeyEvent(newSpeedDial));
      }
    }
  }

  String _getSimLabel(int mode) {
    switch (mode) {
      case 1:
        return 'SIM 1';
      case 2:
        return 'SIM 2';
      case 3:
        return 'Ask';
      default:
        return 'Default SIM';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage 1-9 Speed Dial Keys'),
      ),
      body: BlocBuilder<SpeedDialBloc, SpeedDialState>(
        builder: (context, state) {
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: 9,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final digit = index + 1;
              final assigned = state.speedDialKeys[digit];

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(
                    '$digit',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onPrimaryContainer,
                      fontSize: 18,
                    ),
                  ),
                ),
                title: Text(
                  assigned != null && assigned.phoneNumber.isNotEmpty
                      ? assigned.contactName
                      : 'Unassigned Key #$digit',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  assigned != null && assigned.phoneNumber.isNotEmpty
                      ? '${assigned.phoneLabel}: ${assigned.phoneNumber} • SIM: ${_getSimLabel(assigned.simSelectionMode)}'
                      : 'Tap to assign a contact for 1-tap long press calling',
                ),
                trailing: assigned != null && assigned.phoneNumber.isNotEmpty
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_rounded),
                            tooltip: 'Reassign',
                            onPressed: () => _assignContactToKey(context, digit, assigned),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                            tooltip: 'Remove',
                            onPressed: () {
                              context.read<SpeedDialBloc>().add(RemoveSpeedDialKeyEvent(digit));
                            },
                          ),
                        ],
                      )
                    : IconButton(
                        icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.green),
                        tooltip: 'Assign',
                        onPressed: () => _assignContactToKey(context, digit, null),
                      ),
              );
            },
          );
        },
      ),
    );
  }
}
