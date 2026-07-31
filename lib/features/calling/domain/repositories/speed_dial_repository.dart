import '../models/speed_dial_key_model.dart';

abstract class SpeedDialRepository {
  Future<Map<int, SpeedDialKeyModel>> getSpeedDialKeys();
  Future<void> assignSpeedDialKey(SpeedDialKeyModel model);
  Future<void> removeSpeedDialKey(int keyDigit);
}
