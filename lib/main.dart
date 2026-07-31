import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/di/service_locator.dart';
import 'core/local_storage/hive_storage.dart';
import 'core/localization/app_localizations.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

import 'features/calling/presentation/bloc/blocked_numbers_bloc.dart';
import 'features/calling/presentation/bloc/calling_bloc.dart';
import 'features/calling/presentation/bloc/family_sos_bloc.dart';
import 'features/calling/presentation/bloc/speed_dial_bloc.dart';
import 'features/contacts/presentation/bloc/contacts_bloc.dart';
import 'features/settings/presentation/bloc/settings_bloc.dart';
import 'features/widgets/presentation/bloc/widget_config_bloc.dart';
import 'features/widgets/presentation/bloc/widget_list_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await HiveStorage.init();
  setupServiceLocator();
  runApp(const SpeedCallApp());
}

class SpeedCallApp extends StatelessWidget {
  const SpeedCallApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SettingsBloc>(create: (_) => getIt<SettingsBloc>()..add(LoadSettingsEvent())),
        BlocProvider<WidgetListBloc>(create: (_) => getIt<WidgetListBloc>()),
        BlocProvider<WidgetConfigBloc>(create: (_) => getIt<WidgetConfigBloc>()),
        BlocProvider<ContactsBloc>(create: (_) => getIt<ContactsBloc>()..add(const LoadContactsEvent())),
        BlocProvider<CallingBloc>(create: (_) => getIt<CallingBloc>()),
        BlocProvider<SpeedDialBloc>(create: (_) => getIt<SpeedDialBloc>()..add(LoadSpeedDialKeysEvent())),
        BlocProvider<BlockedNumbersBloc>(create: (_) => getIt<BlockedNumbersBloc>()..add(LoadBlockedNumbersEvent())),
        BlocProvider<FamilySosBloc>(create: (_) => getIt<FamilySosBloc>()..add(LoadFamilySosConfigEvent())),
      ],
      child: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, settingsState) {
          final settings = settingsState.settings;
          final locale = Locale(settings.languageCode);

          return DynamicColorBuilder(
            builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
              return MaterialApp.router(
                title: 'Speed Call Widget',
                debugShowCheckedModeBanner: false,
                routerConfig: appRouter,
                theme: AppTheme.getTheme(
                  settings.themeMode,
                  settings.useDynamicColors ? lightDynamic : null,
                  settings.useDynamicColors ? darkDynamic : null,
                ),
                darkTheme: AppTheme.getDarkTheme(
                  settings.themeMode,
                  settings.useDynamicColors ? darkDynamic : null,
                ),
                themeMode: _getThemeMode(settings.themeMode.name),
                locale: locale,
                supportedLocales: const [
                  Locale('en'),
                  Locale('ar'),
                ],
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
              );
            },
          );
        },
      ),
    );
  }

  ThemeMode _getThemeMode(String modeName) {
    switch (modeName) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
      case 'amoled':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}
