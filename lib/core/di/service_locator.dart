import 'package:get_it/get_it.dart';

import '../../features/calling/data/blocked_numbers_repository_impl.dart';
import '../../features/calling/data/calling_repository_impl.dart';
import '../../features/calling/data/family_sos_repository_impl.dart';
import '../../features/calling/data/speed_dial_repository_impl.dart';
import '../../features/calling/domain/repositories/blocked_numbers_repository.dart';
import '../../features/calling/domain/repositories/calling_repository.dart';
import '../../features/calling/domain/repositories/family_sos_repository.dart';
import '../../features/calling/domain/repositories/speed_dial_repository.dart';
import '../../features/calling/presentation/bloc/blocked_numbers_bloc.dart';
import '../../features/calling/presentation/bloc/calling_bloc.dart';
import '../../features/calling/presentation/bloc/family_sos_bloc.dart';
import '../../features/calling/presentation/bloc/speed_dial_bloc.dart';
import '../../features/contacts/data/contacts_repository_impl.dart';
import '../../features/contacts/domain/repositories/contacts_repository.dart';
import '../../features/contacts/presentation/bloc/contacts_bloc.dart';
import '../../features/settings/data/settings_repository_impl.dart';
import '../../features/settings/domain/repositories/settings_repository.dart';
import '../../features/settings/presentation/bloc/settings_bloc.dart';
import '../../features/widgets/data/widget_repository_impl.dart';
import '../../features/widgets/domain/repositories/widget_repository.dart';
import '../../features/widgets/presentation/bloc/widget_config_bloc.dart';
import '../../features/widgets/presentation/bloc/widget_list_bloc.dart';

final getIt = GetIt.instance;

void setupServiceLocator() {
  // Repositories
  getIt.registerLazySingleton<WidgetRepository>(() => WidgetRepositoryImpl());
  getIt.registerLazySingleton<ContactsRepository>(() => ContactsRepositoryImpl());
  getIt.registerLazySingleton<CallingRepository>(() => CallingRepositoryImpl());
  getIt.registerLazySingleton<SettingsRepository>(() => SettingsRepositoryImpl());
  getIt.registerLazySingleton<SpeedDialRepository>(() => SpeedDialRepositoryImpl());
  getIt.registerLazySingleton<BlockedNumbersRepository>(() => BlockedNumbersRepositoryImpl());
  getIt.registerLazySingleton<FamilySosRepository>(() => FamilySosRepositoryImpl());

  // Blocs
  getIt.registerFactory(() => WidgetListBloc(widgetRepository: getIt()));
  getIt.registerFactory(() => WidgetConfigBloc(widgetRepository: getIt()));
  getIt.registerFactory(() => ContactsBloc(contactsRepository: getIt()));
  getIt.registerFactory(() => CallingBloc(callingRepository: getIt()));
  getIt.registerFactory(() => SettingsBloc(settingsRepository: getIt()));
  getIt.registerFactory(() => SpeedDialBloc(speedDialRepository: getIt()));
  getIt.registerFactory(() => BlockedNumbersBloc(blockedNumbersRepository: getIt()));
  getIt.registerFactory(() => FamilySosBloc(familySosRepository: getIt()));
}
