import 'package:hive_flutter/hive_flutter.dart';
import 'package:vibration/vibration.dart';

import '../../../core/local_storage/hive_storage.dart';
import '../../../core/native/direct_call_platform.dart';
import '../domain/models/call_log_model.dart';
import '../domain/repositories/calling_repository.dart';

class CallingRepositoryImpl implements CallingRepository {
  final Box<Map<dynamic, dynamic>> _box = HiveStorage.callLogsBox;

  @override
  Future<bool> makeCall({
    required String phoneNumber,
    required String contactName,
    int simSelectionMode = 0,
    int? subscriptionId,
  }) async {
    try {
      if (await Vibration.hasVibrator()) {
        Vibration.vibrate(duration: 40);
      }
    } catch (_) {}

    final bool success = await DirectCallPlatform.makeCall(
      phoneNumber: phoneNumber,
      simSelectionMode: simSelectionMode,
      subscriptionId: subscriptionId,
    );

    // ONLY record in call history if the call was actually placed successfully
    if (success) {
      final bool isRecentDuplicate = _box.values.any((item) {
        try {
          final map = Map<String, dynamic>.from(item);
          final phone = map['phoneNumber'] as String?;
          final timeStr = map['timestamp'] as String?;
          if (phone == phoneNumber && timeStr != null) {
            final logTime = DateTime.parse(timeStr);
            return DateTime.now().difference(logTime).inSeconds < 5;
          }
        } catch (_) {}
        return false;
      });

      if (!isRecentDuplicate) {
        final log = CallLogModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          contactName: contactName,
          phoneNumber: phoneNumber,
          simSlotUsed: simSelectionMode,
          timestamp: DateTime.now(),
          wasSuccessful: true,
        );

        await _box.put(log.id, log.toMap());
      }
    }

    return success;
  }

  @override
  Future<List<CallLogModel>> getCallHistory() async {
    final List<CallLogModel> logs = [];
    for (var key in _box.keys) {
      final map = _box.get(key);
      if (map != null) {
        logs.add(CallLogModel.fromMap(Map<String, dynamic>.from(map)));
      }
    }
    logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return logs;
  }

  @override
  Future<void> clearCallHistory() async {
    await _box.clear();
  }
}
