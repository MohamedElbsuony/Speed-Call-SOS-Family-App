import 'dart:convert';
import 'package:flutter/services.dart';

class WidgetPlatform {
  static const MethodChannel _channel = MethodChannel('com.speedcall.app/widgets');

  static Future<bool> saveWidgetConfig({
    required int widgetId,
    required Map<String, dynamic> configMap,
  }) async {
    try {
      final String jsonStr = jsonEncode(configMap);
      final bool result = await _channel.invokeMethod('saveWidgetConfig', {
        'widgetId': widgetId,
        'configJson': jsonStr,
      });
      return result;
    } on PlatformException catch (e) {
      print('Failed to save widget config: ${e.message}');
      return false;
    }
  }

  static Future<bool> pinWidget(Map<String, dynamic> configMap) async {
    try {
      final String jsonStr = jsonEncode(configMap);
      final bool result = await _channel.invokeMethod('pinWidget', {
        'configJson': jsonStr,
      });
      return result;
    } on PlatformException catch (e) {
      print('Failed to pin widget: ${e.message}');
      return false;
    }
  }

  static Future<List<int>> getWidgetIds() async {
    try {
      final List<dynamic>? ids = await _channel.invokeMethod('getWidgetIds');
      if (ids == null) return [];
      return ids.cast<int>();
    } on PlatformException catch (e) {
      print('Failed to get widget IDs: ${e.message}');
      return [];
    }
  }

  static Future<bool> deleteWidget(int widgetId) async {
    try {
      final bool result = await _channel.invokeMethod('deleteWidget', {
        'widgetId': widgetId,
      });
      return result;
    } on PlatformException catch (e) {
      print('Failed to delete widget: ${e.message}');
      return false;
    }
  }
}
