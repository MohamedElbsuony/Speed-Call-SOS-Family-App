import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../widgets/sim_selection_sheet.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../shared/widgets/empty_state_view.dart';
import '../../domain/models/call_log_model.dart';
import '../bloc/calling_bloc.dart';

class CallHistoryScreen extends StatefulWidget {
  final bool embedInTab;

  const CallHistoryScreen({super.key, this.embedInTab = false});

  @override
  State<CallHistoryScreen> createState() => _CallHistoryScreenState();
}

class _CallHistoryScreenState extends State<CallHistoryScreen> {
  String _selectedFilter = 'all'; // all, missed, outgoing, incoming

  @override
  void initState() {
    super.initState();
    context.read<CallingBloc>().add(LoadCallHistoryEvent());
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final content = BlocBuilder<CallingBloc, CallingState>(
      builder: (context, state) {
        if (state is CallingLoadingState) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is CallHistoryLoadedState) {
          final logs = state.logs;

          final filteredLogs = logs.where((log) {
            if (_selectedFilter == 'missed') return log.callType == CallType.missed;
            if (_selectedFilter == 'outgoing') return log.callType == CallType.outgoing;
            if (_selectedFilter == 'incoming') return log.callType == CallType.incoming;
            return true;
          }).toList();

          return Column(
            children: [
              // Localized Filter Chips Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: SegmentedButton<String>(
                  segments: [
                    ButtonSegment(value: 'all', label: Text(loc.get('filter_all'))),
                    ButtonSegment(value: 'missed', label: Text(loc.get('filter_missed'))),
                    ButtonSegment(value: 'outgoing', label: Text(loc.get('filter_outgoing'))),
                    ButtonSegment(value: 'incoming', label: Text(loc.get('filter_incoming'))),
                  ],
                  selected: {_selectedFilter},
                  onSelectionChanged: (set) {
                    setState(() {
                      _selectedFilter = set.first;
                    });
                  },
                ),
              ),

              if (filteredLogs.isEmpty)
                Expanded(
                  child: EmptyStateView(
                    icon: Icons.history_rounded,
                    title: loc.get('no_call_history'),
                    message: loc.get('call_history_empty_msg'),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredLogs.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final log = filteredLogs[index];
                      final formattedDate = DateFormat.yMMMd(loc.locale.languageCode).add_jm().format(log.timestamp);
                      final iconData = _getCallTypeIcon(log.callType);
                      final iconColor = _getCallTypeColor(log.callType, theme);
                      final typeLabel = _getCallTypeLabel(log.callType, loc);

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: iconColor.withValues(alpha: 0.15),
                          child: Icon(iconData, color: iconColor, size: 20),
                        ),
                        title: Text(
                          log.contactName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: log.callType == CallType.missed ? Colors.red : null,
                          ),
                        ),
                        subtitle: Text(
                          '${log.phoneNumber} • $typeLabel • $formattedDate',
                          style: TextStyle(
                            fontSize: 12,
                            color: log.callType == CallType.missed ? Colors.red.shade400 : null,
                          ),
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.call_rounded, color: theme.colorScheme.primary),
                          onPressed: () async {
                            final simMode = await SimSelectionSheet.show(context);
                            if (simMode == null) return;

                            if (context.mounted) {
                              context.read<CallingBloc>().add(
                                    TriggerDirectCallEvent(
                                      phoneNumber: log.phoneNumber,
                                      contactName: log.contactName,
                                      simSelectionMode: simMode,
                                    ),
                                  );
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        }

        return const SizedBox.shrink();
      },
    );

    if (widget.embedInTab) {
      return content;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.get('call_history')),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded),
            onPressed: () {
              context.read<CallingBloc>().add(ClearCallHistoryEvent());
            },
          ),
        ],
      ),
      body: content,
    );
  }

  IconData _getCallTypeIcon(CallType type) {
    switch (type) {
      case CallType.outgoing:
        return Icons.call_made_rounded;
      case CallType.incoming:
        return Icons.call_received_rounded;
      case CallType.missed:
        return Icons.call_missed_rounded;
      case CallType.rejected:
        return Icons.call_missed_outgoing_rounded;
    }
  }

  Color _getCallTypeColor(CallType type, ThemeData theme) {
    switch (type) {
      case CallType.outgoing:
        return theme.colorScheme.primary;
      case CallType.incoming:
        return Colors.green;
      case CallType.missed:
      case CallType.rejected:
        return Colors.red;
    }
  }

  String _getCallTypeLabel(CallType type, AppLocalizations loc) {
    switch (type) {
      case CallType.outgoing:
        return loc.get('call_type_outgoing');
      case CallType.incoming:
        return loc.get('call_type_incoming');
      case CallType.missed:
        return loc.get('call_type_missed');
      case CallType.rejected:
        return loc.get('call_type_rejected');
    }
  }
}
