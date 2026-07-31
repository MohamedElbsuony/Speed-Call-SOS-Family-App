import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:permission_handler/permission_handler.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../calling/presentation/bloc/family_sos_bloc.dart';
import '../../../calling/presentation/screens/call_history_screen.dart';
import '../../../calling/presentation/widgets/dialer_keypad_view.dart';
import '../../../calling/presentation/widgets/sos_trigger_dialog.dart';
import '../../../contacts/presentation/screens/favorites_screen.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  int _selectedBottomIndex = 0; // Keypad is Tab 0 (Primary Default Screen)

  @override
  void initState() {
    super.initState();
    _requestAllAppPermissions();
    _checkInitialSosAction();
  }

  Future<void> _requestAllAppPermissions() async {
    try {
      await [
        Permission.contacts,
        Permission.phone,
        Permission.sms,
        Permission.location,
        Permission.notification,
      ].request();
    } catch (_) {}
  }

  Future<void> _checkInitialSosAction() async {
    try {
      const channel = MethodChannel('com.speedcall.app/direct_call');
      final String? action = await channel.invokeMethod<String>('getInitialAction');
      if (action == 'trigger_family_sos' && mounted) {
        SosTriggerDialog.show(context);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          loc.get('app_title'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          BlocBuilder<FamilySosBloc, FamilySosState>(
            builder: (context, sosState) {
              if (sosState.config.isEnabled) {
                return IconButton(
                  icon: const Icon(Icons.sos_rounded, color: Colors.red),
                  tooltip: 'Family SOS',
                  onPressed: () => SosTriggerDialog.show(context),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          IconButton(
            icon: const Icon(Icons.contacts_rounded),
            tooltip: loc.get('contacts'),
            onPressed: () => context.push('/contacts'),
          ),
          IconButton(
            icon: const Icon(Icons.history_rounded),
            tooltip: loc.get('call_history'),
            onPressed: () => context.push('/call-history'),
          ),
          IconButton(
            icon: CircleAvatar(
              radius: 14,
              backgroundColor: theme.colorScheme.primary,
              child: const Text('MS', style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            tooltip: 'Developer Info',
            onPressed: () => context.push('/about-developer'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            tooltip: loc.get('settings'),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedBottomIndex,
        children: [
          // Tab 0: Primary Default Screen - Fullscreen Dialer Keypad
          const DialerKeypadView(),

          // Tab 1: Recents & Call History
          const CallHistoryScreen(embedInTab: true),

          // Tab 2: Favorites Screen (جهات الاتصال المفضلة)
          const FavoritesScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedBottomIndex,
        onDestinationSelected: (idx) {
          setState(() {
            _selectedBottomIndex = idx;
          });
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dialpad_outlined),
            selectedIcon: const Icon(Icons.dialpad_rounded),
            label: loc.get('keypad'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.history_outlined),
            selectedIcon: const Icon(Icons.history_rounded),
            label: loc.get('call_history'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.star_outline_rounded),
            selectedIcon: const Icon(Icons.star_rounded),
            label: loc.get('favorites'),
          ),
        ],
      ),
      floatingActionButton: _selectedBottomIndex == 2
          ? FloatingActionButton.extended(
              heroTag: 'fab_home_favorites',
              onPressed: () => context.push('/contacts'),
              icon: const Icon(Icons.person_add_rounded),
              label: Text(loc.get('select_contact')),
            )
          : null,
    );
  }
}
