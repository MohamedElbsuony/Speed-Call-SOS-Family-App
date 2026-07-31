import 'package:flutter/material.dart';

import '../../../../core/native/sim_info_platform.dart';

class SimSelectionSheet extends StatefulWidget {
  final int initialSimMode;
  final ValueChanged<int> onSimSelected;

  const SimSelectionSheet({
    super.key,
    required this.initialSimMode,
    required this.onSimSelected,
  });

  static Future<int?> show(BuildContext context, {int initialSimMode = 0}) {
    return showModalBottomSheet<int>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SimSelectionSheet(
        initialSimMode: initialSimMode,
        onSimSelected: (mode) => Navigator.of(context).pop(mode),
      ),
    );
  }

  @override
  State<SimSelectionSheet> createState() => _SimSelectionSheetState();
}

class _SimSelectionSheetState extends State<SimSelectionSheet> {
  List<SimCardInfo> _sims = [];

  @override
  void initState() {
    super.initState();
    _loadSims();
  }

  Future<void> _loadSims() async {
    final list = await SimInfoPlatform.getAvailableSims();
    if (mounted) {
      setState(() {
        _sims = list;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Select SIM Card for Calling',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Choose which SIM slot to place direct call from',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.sim_card_outlined),
              title: const Text('Android Default SIM'),
              subtitle: const Text('Use system default calling SIM'),
              trailing: widget.initialSimMode == 0 ? const Icon(Icons.check_circle, color: Colors.blue) : null,
              onTap: () => widget.onSimSelected(0),
            ),
            ListTile(
              leading: const Icon(Icons.sim_card_rounded, color: Colors.blue),
              title: Text(_getSimName(1)),
              subtitle: const Text('Always call using SIM 1'),
              trailing: widget.initialSimMode == 1 ? const Icon(Icons.check_circle, color: Colors.blue) : null,
              onTap: () => widget.onSimSelected(1),
            ),
            ListTile(
              leading: const Icon(Icons.sim_card_rounded, color: Colors.orange),
              title: Text(_getSimName(2)),
              subtitle: const Text('Always call using SIM 2'),
              trailing: widget.initialSimMode == 2 ? const Icon(Icons.check_circle, color: Colors.blue) : null,
              onTap: () => widget.onSimSelected(2),
            ),
            ListTile(
              leading: const Icon(Icons.question_answer_rounded),
              title: const Text('Ask Every Time'),
              subtitle: const Text('Prompt dialer SIM selector before calling'),
              trailing: widget.initialSimMode == 3 ? const Icon(Icons.check_circle, color: Colors.blue) : null,
              onTap: () => widget.onSimSelected(3),
            ),
          ],
        ),
      ),
    );
  }

  String _getSimName(int slot) {
    final match = _sims.where((s) => s.slotIndex == (slot - 1));
    if (match.isNotEmpty) {
      return 'Always ${match.first.displayName} (${match.first.carrierName})';
    }
    return slot == 1 ? 'Always SIM 1' : 'Always SIM 2';
  }
}
