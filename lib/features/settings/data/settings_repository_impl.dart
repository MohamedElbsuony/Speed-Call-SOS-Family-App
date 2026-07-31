import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/local_storage/hive_storage.dart';
import '../domain/models/settings_model.dart';
import '../domain/repositories/settings_repository.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final Box<Map<dynamic, dynamic>> _box = HiveStorage.settingsBox;
  static const String _key = 'user_settings';

  @override
  Future<SettingsModel> getSettings() async {
    final map = _box.get(_key);
    if (map == null) return const SettingsModel();
    return SettingsModel.fromMap(Map<String, dynamic>.from(map));
  }

  @override
  Future<void> saveSettings(SettingsModel settings) async {
    await _box.put(_key, settings.toMap());
  }
}
