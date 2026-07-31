import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../shared/widgets/empty_state_view.dart';
import '../../domain/models/blocked_number_model.dart';
import '../bloc/blocked_numbers_bloc.dart';

class BlockedNumbersScreen extends StatelessWidget {
  const BlockedNumbersScreen({super.key});

  void _showAddBlockDialog(BuildContext context) {
    final numberController = TextEditingController();
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block Phone Number'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name (Optional)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: numberController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone Number'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final number = numberController.text.trim();
              if (number.isNotEmpty) {
                final model = BlockedNumberModel(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  phoneNumber: number,
                  contactName: nameController.text.isNotEmpty ? nameController.text : 'Blocked Contact',
                  blockedAt: DateTime.now(),
                );
                context.read<BlockedNumbersBloc>().add(BlockNumberEvent(model));
                Navigator.of(context).pop();
              }
            },
            child: const Text('Block'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Blocked Contacts & Spam'),
      ),
      body: BlocBuilder<BlockedNumbersBloc, BlockedNumbersState>(
        builder: (context, state) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.blockedNumbers.isEmpty) {
            return EmptyStateView(
              icon: Icons.block_rounded,
              title: 'No Blocked Numbers',
              message: 'Numbers you block will not trigger accidental speed calls.',
              buttonText: 'Block a Number',
              onButtonPressed: () => _showAddBlockDialog(context),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: state.blockedNumbers.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = state.blockedNumbers[index];
              final dateStr = DateFormat.yMMMd().format(item.blockedAt);

              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: theme.colorScheme.errorContainer,
                  child: Icon(Icons.block_rounded, color: theme.colorScheme.onErrorContainer),
                ),
                title: Text(item.contactName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${item.phoneNumber} • Blocked on $dateStr'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                  tooltip: 'Unblock',
                  onPressed: () {
                    context.read<BlockedNumbersBloc>().add(UnblockNumberEvent(item.id));
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_blocked_numbers',
        onPressed: () => _showAddBlockDialog(context),
        icon: const Icon(Icons.add_moderator_rounded),
        label: const Text('Block Number'),
      ),
    );
  }
}
