import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:permission_handler/permission_handler.dart';

import '../../../core/local_storage/hive_storage.dart';
import '../../../core/native/direct_call_platform.dart';
import '../domain/models/family_sos_config_model.dart';
import '../domain/repositories/family_sos_repository.dart';

class EmergencyContactEntry {
  final String name;
  final String phone;

  EmergencyContactEntry({required this.name, required this.phone});

  factory EmergencyContactEntry.parse(String raw) {
    if (raw.contains('|')) {
      final parts = raw.split('|');
      return EmergencyContactEntry(
        name: parts[0].trim(),
        phone: parts.sublist(1).join('|').trim(),
      );
    }
    return EmergencyContactEntry(name: raw.trim(), phone: raw.trim());
  }
}

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
      try {
        var status = await Permission.location.status;
        if (!status.isGranted) {
          status = await Permission.location.request();
        }

        const directChannel = MethodChannel('com.speedcall.app/direct_call');
        await directChannel.invokeMethod<bool>('checkAndEnableGps');

        final String? gpsCoords = await directChannel.invokeMethod<String>('getGpsLocation');
        if (gpsCoords != null && gpsCoords.isNotEmpty) {
          crisisMessage += '\n\n📍 موقع الطوارئ المباشر (GPS):\nhttps://www.google.com/maps/search/?api=1&query=$gpsCoords';
        } else {
          crisisMessage += '\n\n📍 موقع الطوارئ المباشر:\nhttps://maps.google.com';
        }
      } catch (_) {
        crisisMessage += '\n\n📍 موقع الطوارئ المباشر:\nhttps://maps.google.com';
      }
    }

    final entries = config.emergencyContacts.map((raw) => EmergencyContactEntry.parse(raw)).toList();

    // Mode 0: Voice Call Only
    if (mode == 0) {
      if (config.primaryCallNumber.isNotEmpty) {
        await DirectCallPlatform.makeCall(
          phoneNumber: config.primaryCallNumber,
          simSelectionMode: 0,
        );
      } else if (entries.isNotEmpty) {
        await DirectCallPlatform.makeCall(
          phoneNumber: entries.first.phone,
          simSelectionMode: 0,
        );
      }
      return;
    }

    // Mode 1: WhatsApp Alert (Guaranteed Hybrid Delivery)
    // Send instant background SMS to ALL emergency numbers so everyone receives the crisis alert immediately,
    // AND launch WhatsApp for primary contact with the pre-filled message!
    if (mode == 1) {
      for (var entry in entries) {
        final cleanPhone = entry.phone.replaceAll(RegExp(r'[^0-9+]'), '');
        if (cleanPhone.isEmpty) continue;

        try {
          await _smsChannel.invokeMethod('sendDirectSms', {
            'phoneNumber': cleanPhone,
            'message': crisisMessage,
          });
        } catch (_) {}
      }

      String targetPhone = config.primaryCallNumber;
      if (targetPhone.isEmpty && entries.isNotEmpty) {
        targetPhone = entries.first.phone;
      }

      final cleanWaPhone = targetPhone.replaceAll(RegExp(r'[^0-9+]'), '').replaceAll('+', '');
      if (cleanWaPhone.isNotEmpty) {
        final whatsappUrl = Uri.parse("https://wa.me/$cleanWaPhone?text=${Uri.encodeComponent(crisisMessage)}");
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
      for (var entry in entries) {
        final cleanPhone = entry.phone.replaceAll(RegExp(r'[^0-9+]'), '');
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
