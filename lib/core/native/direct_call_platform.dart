import 'package:flutter/services.dart';

class DirectCallPlatform {
  static const MethodChannel _channel = MethodChannel('com.speedcall.app/direct_call');

  /// Makes a direct call using native Android ACTION_CALL
  /// [simSelectionMode]: 0 = Default, 1 = SIM 1, 2 = SIM 2, 3 = Ask
  static Future<bool> makeCall({
    required String phoneNumber,
    int simSelectionMode = 0,
    int? subscriptionId,
  }) async {
    try {
      final bool result = await _channel.invokeMethod('makeCall', {
        'phoneNumber': phoneNumber,
        'simSelectionMode': simSelectionMode,
        'subscriptionId': subscriptionId,
      });
      return result;
    } on PlatformException catch (e) {
      print('Failed to make direct call: ${e.message}');
      return false;
    }
  }
}
