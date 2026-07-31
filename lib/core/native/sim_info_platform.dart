import 'package:flutter/services.dart';

class SimCardInfo {
  final int slotIndex;
  final int subscriptionId;
  final String carrierName;
  final String displayName;
  final String iccId;

  SimCardInfo({
    required this.slotIndex,
    required this.subscriptionId,
    required this.carrierName,
    required this.displayName,
    required this.iccId,
  });

  factory SimCardInfo.fromMap(Map<dynamic, dynamic> map) {
    return SimCardInfo(
      slotIndex: map['slotIndex'] as int? ?? 0,
      subscriptionId: map['subscriptionId'] as int? ?? 0,
      carrierName: map['carrierName'] as String? ?? 'SIM',
      displayName: map['displayName'] as String? ?? 'SIM',
      iccId: map['iccId'] as String? ?? '',
    );
  }
}

class SimInfoPlatform {
  static const MethodChannel _channel = MethodChannel('com.speedcall.app/sim_info');

  static Future<List<SimCardInfo>> getAvailableSims() async {
    try {
      final List<dynamic>? sims = await _channel.invokeMethod('getAvailableSims');
      if (sims == null) return [];
      return sims.map((item) => SimCardInfo.fromMap(item as Map<dynamic, dynamic>)).toList();
    } on PlatformException catch (e) {
      print('Failed to get SIM info: ${e.message}');
      return [];
    }
  }
}
