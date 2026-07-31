import 'package:hive_flutter/hive_flutter.dart';

class HiveStorage {
  static const String widgetsBoxName = 'widgets_box';
  static const String callLogsBoxName = 'call_logs_box';
  static const String settingsBoxName = 'settings_box';
  static const String pinnedContactsBoxName = 'pinned_contacts_box';
  static const String favoriteContactsBoxName = 'favorite_contacts_box';
  static const String speedDialBoxName = 'speed_dial_box';
  static const String blockedNumbersBoxName = 'blocked_numbers_box';
  static const String familySosBoxName = 'family_sos_box';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox<Map<dynamic, dynamic>>(widgetsBoxName);
    await Hive.openBox<Map<dynamic, dynamic>>(callLogsBoxName);
    await Hive.openBox<Map<dynamic, dynamic>>(settingsBoxName);
    await Hive.openBox<String>(pinnedContactsBoxName);
    await Hive.openBox<String>(favoriteContactsBoxName);
    await Hive.openBox<Map<dynamic, dynamic>>(speedDialBoxName);
    await Hive.openBox<Map<dynamic, dynamic>>(blockedNumbersBoxName);
    await Hive.openBox<Map<dynamic, dynamic>>(familySosBoxName);
  }

  static Box<Map<dynamic, dynamic>> get widgetsBox =>
      Hive.box<Map<dynamic, dynamic>>(widgetsBoxName);

  static Box<Map<dynamic, dynamic>> get callLogsBox =>
      Hive.box<Map<dynamic, dynamic>>(callLogsBoxName);

  static Box<Map<dynamic, dynamic>> get settingsBox =>
      Hive.box<Map<dynamic, dynamic>>(settingsBoxName);

  static Box<String> get pinnedContactsBox =>
      Hive.box<String>(pinnedContactsBoxName);

  static Box<String> get favoriteContactsBox =>
      Hive.box<String>(favoriteContactsBoxName);

  static Box<Map<dynamic, dynamic>> get speedDialBox =>
      Hive.box<Map<dynamic, dynamic>>(speedDialBoxName);

  static Box<Map<dynamic, dynamic>> get blockedNumbersBox =>
      Hive.box<Map<dynamic, dynamic>>(blockedNumbersBoxName);

  static Box<Map<dynamic, dynamic>> get familySosBox =>
      Hive.box<Map<dynamic, dynamic>>(familySosBoxName);
}
