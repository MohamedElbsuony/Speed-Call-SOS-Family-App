import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/local_storage/hive_storage.dart';
import '../domain/models/speed_dial_key_model.dart';
import '../domain/repositories/speed_dial_repository.dart';

class SpeedDialRepositoryImpl implements SpeedDialRepository {
  final Box<Map<dynamic, dynamic>> _box = HiveStorage.speedDialBox;

  @override
  Future<Map<int, SpeedDialKeyModel>> getSpeedDialKeys() async {
    final Map<int, SpeedDialKeyModel> map = {};
    for (var key in _box.keys) {
      final item = _box.get(key);
      if (item != null) {
        final castedMap = Map<String, dynamic>.from(item);
        final model = SpeedDialKeyModel.fromMap(castedMap);
        map[model.keyDigit] = model;
      }
    }
    return map;
  }

  @override
  Future<void> assignSpeedDialKey(SpeedDialKeyModel model) async {
    await _box.put(model.keyDigit.toString(), model.toMap());
  }

  @override
  Future<void> removeSpeedDialKey(int keyDigit) async {
    await _box.delete(keyDigit.toString());
  }
}
