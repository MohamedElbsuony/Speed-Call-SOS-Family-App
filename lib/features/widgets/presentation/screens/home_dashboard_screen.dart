import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/native/direct_call_platform.dart';
import '../../../calling/presentation/bloc/calling_bloc.dart';
import '../../../calling/presentation/bloc/family_sos_bloc.dart';
import '../../../calling/presentation/screens/call_history_screen.dart';
import '../../../calling/presentation/screens/in_call_screen.dart';
import '../../../calling/presentation/widgets/dialer_keypad_view.dart';
import '../../../calling/presentation/widgets/sos_trigger_dialog.dart';
import '../../../contacts/presentation/bloc/contacts_bloc.dart';
import '../../../contacts/presentation/screens/contacts_screen.dart';
import '../../../contacts/presentation/screens/favorites_screen.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen>
    with WidgetsBindingObserver {
  int _selectedBottomIndex = 0; // Keypad is Tab 0 (Primary Default Screen)
  StreamSubscription<Map<String, dynamic>>? _callStateSub;
  bool _isInCallScreenOpen = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _requestAllAppPermissions();
    _checkInitialSosAction();
    _initCallStateListener();
  }

  void _initCallStateListener() {
    _callStateSub = DirectCallPlatform.callStateStream.listen((data) {
      if (!mounted) return;
      final state = data['state'] as String? ?? '';
      final phone = data['phoneNumber'] as String? ?? '';
      final isIncoming = data['isIncoming'] as bool? ?? false;

      if ((state == 'RINGING' || state == 'DIALING' || state == 'ACTIVE') && !_isInCallScreenOpen) {
        _isInCallScreenOpen = true;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => InCallScreen(
              phoneNumber: phone,
              contactName: phone,
              isIncoming: isIncoming,
              initialCallState: state,
            ),
          ),
        ).then((_) {
          _isInCallScreenOpen = false;
          if (mounted) {
            context.read<CallingBloc>().add(LoadCallHistoryEvent());
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _callStateSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkInitialSosAction();
      context
          .read<ContactsBloc>()
          .add(const LoadContactsEvent(forceRefresh: true));
      context.read<CallingBloc>().add(LoadCallHistoryEvent());
    }
  }

  Future<void> _requestAllAppPermissions() async {
    try {
      await [
        Permission.contacts,
        Permission.phone,
        Permission.microphone,
        Permission.sms,
        Permission.location,
        Permission.notification,
      ].request();
    } catch (_) {}
  }

  Future<void> _checkInitialSosAction() async {
    try {
      const channel = MethodChannel('com.speedcall.app/direct_call');
      final String? action =
          await channel.invokeMethod<String>('getInitialAction');
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
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.bolt_rounded,
                color: theme.colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              loc.get('app_title'),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        actions: [
          BlocBuilder<FamilySosBloc, FamilySosState>(
            builder: (context, sosState) {
              if (sosState.config.isEnabled) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: InkWell(
                    onTap: () => SosTriggerDialog.show(context),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withValues(alpha: 0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.warning_amber_rounded, size: 16, color: Colors.white),
                          SizedBox(width: 4),
                          Text(
                            'SOS',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded, size: 24),
            tooltip: loc.get('settings'),
            onPressed: () => context.push('/settings'),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded, size: 24),
            tooltip: 'المزيد',
            onSelected: (value) {
              if (value == 'developer') {
                context.push('/about-developer');
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'developer',
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      child: Text('MS', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
                    ),
                    SizedBox(width: 10),
                    Text('معلومات المطور'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: IndexedStack(
        index: _selectedBottomIndex,
        children: const [
          // Tab 0: Keypad
          DialerKeypadView(),

          // Tab 1: Contacts (الأسماء)
          ContactsScreen(embedInTab: true),

          // Tab 2: Recents & Call History
          CallHistoryScreen(embedInTab: true),

          // Tab 3: Favorites Screen (جهات الاتصال المفضلة)
          FavoritesScreen(),
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
            icon: const Icon(Icons.people_outline_rounded),
            selectedIcon: const Icon(Icons.people_rounded),
            label: loc.get('contacts'),
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
      floatingActionButton: _selectedBottomIndex == 3
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
