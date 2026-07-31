import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/local_storage/hive_storage.dart';
import '../../../core/native/direct_call_platform.dart';
import '../domain/models/family_sos_config_model.dart';
import '../domain/repositories/family_sos_repository.dart';

class FamilySosRepositoryImpl implements FamilySosRepository {
  final Box<Map<dynamic, dynamic>> _box = HiveStorage.familySosBox;
  static const MethodChannel _smsChannel = MethodChannel('com.speedcall.app/sms');
  static const MethodChannel _widgetChannel = MethodChannel('com.speedcall.app/widgets');

  static const String _key = 'sos_config';

  @override
  Future<FamilySosConfigModel> getFamilySosConfig() async {
    final data = _box.get(_key);
    if (data != null) {
      final config = FamilySosConfigModel.fromMap(Map<String, dynamic>.from(data));
      _syncToNativePrefs(config.toMap());
      return config;
    }
    return const FamilySosConfigModel();
  }

  @override
  Future<void> saveFamilySosConfig(FamilySosConfigModel config) async {
    final mapData = config.toMap();
    await _box.put(_key, mapData);
    await _syncToNativePrefs(mapData);
  }

  Future<void> _syncToNativePrefs(Map<String, dynamic> mapData) async {
    try {
      final jsonString = jsonEncode(mapData);
      await _widgetChannel.invokeMethod('saveSosConfig', {'configJson': jsonString});
    } catch (_) {}
  }

  @override
  Future<bool> pinSosWidgetToHomeScreen() async {
    try {
      final bool? success = await _widgetChannel.invokeMethod<bool>('pinSosWidget');
      return success ?? false;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> dispatchEmergencyAlert(FamilySosConfigModel config) async {
    final mode = config.sosActionMode; // 0: Call Only, 1: WhatsApp Only, 2: SMS Only

    String crisisMessage = config.sosMessageText;
    if (config.includeLocation) {
      crisisMessage += '\n\n📍 موقع الطوارئ المباشر:\nhttps://maps.google.com/?q=EmergencyAlertLocation';
    }

    // Mode 0: Voice Call Only (Default)
    if (mode == 0) {
      if (config.primaryCallNumber.isNotEmpty) {
        await DirectCallPlatform.makeCall(
          phoneNumber: config.primaryCallNumber,
          simSelectionMode: 0,
        );
      } else if (config.emergencyContacts.isNotEmpty) {
        await DirectCallPlatform.makeCall(
          phoneNumber: config.emergencyContacts.first,
          simSelectionMode: 0,
        );
      }
      return;
    }

    // Mode 1: WhatsApp Message Only
    if (mode == 1) {
      for (String phone in config.emergencyContacts) {
        final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '').replaceAll('+', '');
        if (cleanPhone.isEmpty) continue;

        final whatsappUrl = Uri.parse("https://wa.me/$cleanPhone?text=${Uri.encodeComponent(crisisMessage)}");
        try {
          if (await canLaunchUrl(whatsappUrl)) {
            await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
          }
        } catch (_) {}
      }
      return;
    }

    // Mode 2: Offline Direct SMS Only
    if (mode == 2) {
      for (String phone in config.emergencyContacts) {
        final cleanPhone = phone.replaceAll(RegExp(r'[^0-9+]'), '');
        if (cleanPhone.isEmpty) continue;

        try {
          await _smsChannel.invokeMethod('sendDirectSms', {
            'phoneNumber': cleanPhone,
            'message': crisisMessage,
          });
        } catch (_) {}
      }
      return;
    }
  }
}
