import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:vibration/vibration.dart';

import '../../../../core/native/direct_call_platform.dart';
import '../bloc/family_sos_bloc.dart';

class SosTriggerDialog extends StatefulWidget {
  const SosTriggerDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const SosTriggerDialog(),
    );
  }

  @override
  State<SosTriggerDialog> createState() => _SosTriggerDialogState();
}

class _SosTriggerDialogState extends State<SosTriggerDialog> {
  int _secondsLeft = 3;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _triggerVibration();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 1) {
        setState(() {
          _secondsLeft--;
        });
        _triggerVibration();
      } else {
        _timer?.cancel();
        Navigator.of(context).pop();
        _executeEmergencyFlow();
      }
    });
  }

  void _executeEmergencyFlow() async {
    final sosState = context.read<FamilySosBloc>().state;
    final config = sosState.config;

    // Trigger repository dispatch
    context.read<FamilySosBloc>().add(const TriggerEmergencyAlertEvent());

    // In Voice Call Only Mode (0) or Default: Directly dial primary target without opening duplicate dialogs
    if (config.sosActionMode == 0) {
      String targetPhone = config.primaryCallNumber.trim();
      if (targetPhone.isEmpty && config.emergencyContacts.isNotEmpty) {
        targetPhone = config.emergencyContacts.first.trim();
      }

      if (targetPhone.isNotEmpty) {
        await DirectCallPlatform.makeCall(
          phoneNumber: targetPhone,
          simSelectionMode: 0,
        );
      }
    }
  }

  void _triggerVibration() async {
    try {
      final hasVib = await Vibration.hasVibrator();
      if (hasVib == true) {
        Vibration.vibrate(duration: 300);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      backgroundColor: theme.colorScheme.errorContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: theme.colorScheme.onErrorContainer, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'طوارئ العائلة (FAMILY SOS)',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: theme.colorScheme.onErrorContainer,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'جاري تنفيذ التنبيهات والاتصال المباشر خلال:',
            textAlign: TextAlign.center,
            style: TextStyle(color: theme.colorScheme.onErrorContainer),
          ),
          const SizedBox(height: 16),
          CircleAvatar(
            radius: 36,
            backgroundColor: theme.colorScheme.error,
            child: Text(
              '$_secondsLeft',
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      actions: [
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
          ),
          onPressed: () {
            _timer?.cancel();
            Navigator.of(context).pop();
          },
          child: const Text('إلغاء (CANCEL)', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
