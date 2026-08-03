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

    if (success) {
      final log = CallLogModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        contactName: contactName,
        phoneNumber: phoneNumber,
        simSlotUsed: simSelectionMode,
        timestamp: DateTime.now(),
        wasSuccessful: true,
        callType: CallType.outgoing,
      );
      await saveCallLog(log);
    }

    return success;
  }

  @override
  Future<void> saveCallLog(CallLogModel log) async {
    final bool isRecentDuplicate = _box.values.any((item) {
      try {
        final map = Map<String, dynamic>.from(item);
        final phone = map['phoneNumber'] as String?;
        final timeStr = map['timestamp'] as String?;
        if (phone == log.phoneNumber && timeStr != null) {
          final logTime = DateTime.parse(timeStr);
          return log.timestamp.difference(logTime).inSeconds.abs() < 4;
        }
      } catch (_) {}
      return false;
    });

    if (!isRecentDuplicate) {
      await _box.put(log.id, log.toMap());
    }
  }

  @override
  Future<void> syncSystemCallLogs() async {
    try {
      final systemLogs = await DirectCallPlatform.getSystemCallLogs();
      for (final item in systemLogs) {
        final String id = item['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString();
        final String phone = item['phoneNumber']?.toString() ?? '';
        final String name = item['contactName']?.toString() ?? phone;
        final String typeStr = item['callType']?.toString() ?? 'incoming';
        final int timestampMs = item['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch;
        final int durationSeconds = item['durationSeconds'] as int? ?? 0;

        CallType callType = CallType.incoming;
        if (typeStr == 'outgoing') callType = CallType.outgoing;
        if (typeStr == 'missed') callType = CallType.missed;
        if (typeStr == 'rejected') callType = CallType.rejected;

        final log = CallLogModel(
          id: 'sys_$id',
          contactName: name.isNotEmpty ? name : phone,
          phoneNumber: phone,
          simSlotUsed: 0,
          timestamp: DateTime.fromMillisecondsSinceEpoch(timestampMs),
          wasSuccessful: callType != CallType.missed && callType != CallType.rejected,
          callType: callType,
          durationSeconds: durationSeconds,
        );

        if (!_box.containsKey(log.id)) {
          await _box.put(log.id, log.toMap());
        }
      }
    } catch (e) {
      print('Error syncing system call logs: $e');
    }
  }

  @override
  Future<List<CallLogModel>> getCallHistory() async {
    await syncSystemCallLogs();
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
