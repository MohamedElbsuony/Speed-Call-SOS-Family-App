import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../widgets/sim_selection_sheet.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/native/direct_call_platform.dart';
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
  bool _isDefaultDialer = false;

  @override
  void initState() {
    super.initState();
    _checkDefaultDialerStatus();
    context.read<CallingBloc>().add(LoadCallHistoryEvent());
  }

  Future<void> _checkDefaultDialerStatus() async {
    final isDefault = await DirectCallPlatform.isDefaultDialer();
    if (mounted) {
      setState(() {
        _isDefaultDialer = isDefault;
      });
    }
  }

  Future<void> _requestDefaultDialer() async {
    await DirectCallPlatform.requestDefaultDialer();
    await Future.delayed(const Duration(seconds: 1));
    final isDefault = await DirectCallPlatform.isDefaultDialer();
    if (mounted) {
      setState(() {
        _isDefaultDialer = isDefault;
      });
      if (!isDefault) {
        _showRestrictedSettingsGuide();
      }
    }
  }

  void _showRestrictedSettingsGuide() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.security_rounded, color: Colors.orangeAccent),
            SizedBox(width: 8),
            Expanded(
              child: Text("السماح بالإعدادات المحظورة", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "في نظام أندرويد الحديث، يتم حظر صلاحية الاتصال الافتراضي للتطبيقات المثبتة يدويًا (APK). لتمكينها بسهولة:",
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
            SizedBox(height: 12),
            Text("1️⃣ اضغط على \"فتح إعدادات التطبيق\" بالأسفل.", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text("2️⃣ اضغط على الـ 3 نقاط (⋮) أعلى اليمين.", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text("3️⃣ اختر \"السماح بالإعدادات المحظورة\" (Allow restricted settings).", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text("4️⃣ عد للتطبيق واضغط \"تعيين كافتراضي\" مجددًا.", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("إلغاء"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              DirectCallPlatform.openAppSettings();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
            child: const Text("فتح إعدادات التطبيق", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
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
              // Default Dialer Banner
              if (!_isDefaultDialer)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primaryContainer,
                        theme.colorScheme.surfaceContainerHigh,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.phone_in_talk_rounded, color: theme.colorScheme.primary, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "تعيين كـ تطبيق الاتصال الافتراضي",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "لتحكم كامل بالمكالمات وإظهار شاشتك الخاصة وسجل المكالمات الواردة والفائتة",
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _requestDefaultDialer,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text("تعيين", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ),
                ),

              // Filter Chips
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
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
                  child: RefreshIndicator(
                    onRefresh: () async {
                      context.read<CallingBloc>().add(LoadCallHistoryEvent());
                    },
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

                        final durationText = log.durationSeconds > 0
                            ? ' • ${(log.durationSeconds ~/ 60)}m ${log.durationSeconds % 60}s'
                            : '';

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
                            '${log.phoneNumber} • $typeLabel$durationText\n$formattedDate',
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
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              context.read<CallingBloc>().add(LoadCallHistoryEvent());
            },
          ),
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
