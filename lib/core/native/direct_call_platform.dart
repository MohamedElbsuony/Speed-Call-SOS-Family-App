import 'package:flutter/services.dart';

class DirectCallPlatform {
  static const MethodChannel _channel = MethodChannel('com.speedcall.app/direct_call');
  static const EventChannel _callStateEventChannel = EventChannel('com.speedcall.app/call_state');

  /// Stream of live call state events from Android Telecom InCallService
  static Stream<Map<String, dynamic>> get callStateStream {
    return _callStateEventChannel.receiveBroadcastStream().map((event) {
      if (event is Map) {
        return Map<String, dynamic>.from(event);
      }
      return <String, dynamic>{};
    });
  }

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

  /// Checks if Speed Call is set as the default dialer (Default Phone App)
  static Future<bool> isDefaultDialer() async {
    try {
      final bool result = await _channel.invokeMethod('isDefaultDialer');
      return result;
    } on PlatformException catch (e) {
      print('Failed to check default dialer: ${e.message}');
      return false;
    }
  }

  /// Prompts the user to set Speed Call as the default dialer app
  static Future<bool> requestDefaultDialer() async {
    try {
      final bool result = await _channel.invokeMethod('requestDefaultDialer');
      return result;
    } on PlatformException catch (e) {
      print('Failed to request default dialer: ${e.message}');
      return false;
    }
  }

  /// Opens App Settings screen to allow restricted settings on Android 13+
  static Future<bool> openAppSettings() async {
    try {
      final bool result = await _channel.invokeMethod('openAppSettings');
      return result;
    } on PlatformException catch (e) {
      print('Failed to open app settings: ${e.message}');
      return false;
    }
  }

  /// Answers an incoming call
  static Future<bool> answerCall() async {
    try {
      final bool result = await _channel.invokeMethod('answerCall');
      return result;
    } on PlatformException catch (e) {
      print('Failed to answer call: ${e.message}');
      return false;
    }
  }

  /// Rejects an incoming call
  static Future<bool> rejectCall() async {
    try {
      final bool result = await _channel.invokeMethod('rejectCall');
      return result;
    } on PlatformException catch (e) {
      print('Failed to reject call: ${e.message}');
      return false;
    }
  }

  /// Disconnects / hangs up an active or outgoing call
  static Future<bool> hangUp() async {
    try {
      final bool result = await _channel.invokeMethod('hangUp');
      return result;
    } on PlatformException catch (e) {
      print('Failed to hang up: ${e.message}');
      return false;
    }
  }

  /// Sets microphone mute state during active call
  static Future<bool> setMuted(bool muted) async {
    try {
      final bool result = await _channel.invokeMethod('setMuted', {'muted': muted});
      return result;
    } on PlatformException catch (e) {
      print('Failed to set mute state: ${e.message}');
      return false;
    }
  }

  /// Sets speakerphone state during active call
  static Future<bool> setSpeaker(bool speakerOn) async {
    try {
      final bool result = await _channel.invokeMethod('setSpeaker', {'speakerOn': speakerOn});
      return result;
    } on PlatformException catch (e) {
      print('Failed to set speaker state: ${e.message}');
      return false;
    }
  }

  /// Plays DTMF keypad tone during active call
  static Future<bool> playDtmfTone(String digit) async {
    try {
      final bool result = await _channel.invokeMethod('playDtmfTone', {'digit': digit});
      return result;
    } on PlatformException catch (e) {
      print('Failed to play DTMF tone: ${e.message}');
      return false;
    }
  }

  /// Fetches historical call logs from system content provider
  static Future<List<Map<String, dynamic>>> getSystemCallLogs() async {
    try {
      final List<dynamic> logs = await _channel.invokeMethod('getSystemCallLogs');
      return logs.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } on PlatformException catch (e) {
      print('Failed to fetch system call logs: ${e.message}');
      return [];
    }
  }
}
