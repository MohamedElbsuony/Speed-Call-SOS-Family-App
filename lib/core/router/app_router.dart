import 'package:go_router/go_router.dart';

import '../../features/calling/presentation/screens/blocked_numbers_screen.dart';
import '../../features/calling/presentation/screens/call_analytics_screen.dart';
import '../../features/calling/presentation/screens/call_history_screen.dart';
import '../../features/calling/presentation/screens/family_sos_config_screen.dart';
import '../../features/calling/presentation/screens/speed_dial_manager_screen.dart';
import '../../features/contacts/presentation/screens/contacts_screen.dart';
import '../../features/settings/presentation/screens/about_developer_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/widgets/domain/models/widget_config_model.dart';
import '../../features/widgets/presentation/screens/home_dashboard_screen.dart';
import '../../features/widgets/presentation/screens/widget_config_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeDashboardScreen(),
    ),
    GoRoute(
      path: '/contacts',
      builder: (context, state) {
        final isSelecting = state.uri.queryParameters['select'] == 'true';
        return ContactsScreen(isSelectingForWidget: isSelecting);
      },
    ),
    GoRoute(
      path: '/widget-config',
      builder: (context, state) {
        final config = state.extra as WidgetConfigModel?;
        return WidgetConfigScreen(initialConfig: config);
      },
    ),
    GoRoute(
      path: '/call-history',
      builder: (context, state) => const CallHistoryScreen(),
    ),
    GoRoute(
      path: '/blocked-numbers',
      builder: (context, state) => const BlockedNumbersScreen(),
    ),
    GoRoute(
      path: '/analytics',
      builder: (context, state) => const CallAnalyticsScreen(),
    ),
    GoRoute(
      path: '/family-sos',
      builder: (context, state) => const FamilySosConfigScreen(),
    ),
    GoRoute(
      path: '/speed-dial-manager',
      builder: (context, state) => const SpeedDialManagerScreen(),
    ),
    GoRoute(
      path: '/about-developer',
      builder: (context, state) => const AboutDeveloperScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);
