import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/calling_bloc.dart';

class CallAnalyticsScreen extends StatefulWidget {
  const CallAnalyticsScreen({super.key});

  @override
  State<CallAnalyticsScreen> createState() => _CallAnalyticsScreenState();
}

class _CallAnalyticsScreenState extends State<CallAnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    context.read<CallingBloc>().add(LoadCallHistoryEvent());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Call Statistics & Analytics'),
      ),
      body: BlocBuilder<CallingBloc, CallingState>(
        builder: (context, state) {
          if (state is CallingLoadingState) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is CallHistoryLoadedState) {
            final logs = state.logs;
            final totalCalls = logs.length;
            final successfulCalls = logs.where((l) => l.wasSuccessful).length;

            final Map<String, int> contactFrequency = {};
            for (var l in logs) {
              contactFrequency[l.contactName] = (contactFrequency[l.contactName] ?? 0) + 1;
            }

            final topContacts = contactFrequency.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        theme,
                        title: 'Total Calls',
                        value: '$totalCalls',
                        icon: Icons.phone_callback_rounded,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricCard(
                        theme,
                        title: 'Successful',
                        value: '$successfulCalls',
                        icon: Icons.check_circle_outline_rounded,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                Text(
                  'Top Called Contacts',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                if (topContacts.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Center(child: Text('No call data recorded yet')),
                    ),
                  )
                else
                  ...topContacts.take(5).map((entry) {
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: theme.colorScheme.primaryContainer,
                          child: Text(
                            entry.key.isNotEmpty ? entry.key[0].toUpperCase() : '?',
                            style: TextStyle(
                              color: theme.colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${entry.value} calls placed'),
                        trailing: Icon(Icons.star_rounded, color: Colors.amber[700]),
                      ),
                    );
                  }),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildMetricCard(
    ThemeData theme, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(value, style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
            Text(title, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
