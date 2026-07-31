import 'package:equatable/equatable.dart';

class FamilySosConfigModel extends Equatable {
  final bool isEnabled;
  final String primaryCallNumber;
  final String primaryCallName;
  final List<String> emergencyContacts;
  final String sosMessageText;
  final bool includeLocation;
  final bool enableSmsFallback;
  final int sosActionMode; // 0: Call Only, 1: WhatsApp Only, 2: SMS Only

  const FamilySosConfigModel({
    this.isEnabled = true,
    this.primaryCallNumber = '',
    this.primaryCallName = '',
    this.emergencyContacts = const [],
    this.sosMessageText = '⚠️ EMERGENCY ALERT! I am in an urgent crisis. Please reach out to me immediately!',
    this.includeLocation = true,
    this.enableSmsFallback = true,
    this.sosActionMode = 0,
  });

  FamilySosConfigModel copyWith({
    bool? isEnabled,
    String? primaryCallNumber,
    String? primaryCallName,
    List<String>? emergencyContacts,
    String? sosMessageText,
    bool? includeLocation,
    bool? enableSmsFallback,
    int? sosActionMode,
  }) {
    return FamilySosConfigModel(
      isEnabled: isEnabled ?? this.isEnabled,
      primaryCallNumber: primaryCallNumber ?? this.primaryCallNumber,
      primaryCallName: primaryCallName ?? this.primaryCallName,
      emergencyContacts: emergencyContacts ?? this.emergencyContacts,
      sosMessageText: sosMessageText ?? this.sosMessageText,
      includeLocation: includeLocation ?? this.includeLocation,
      enableSmsFallback: enableSmsFallback ?? this.enableSmsFallback,
      sosActionMode: sosActionMode ?? this.sosActionMode,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isEnabled': isEnabled,
      'primaryCallNumber': primaryCallNumber,
      'primaryCallName': primaryCallName,
      'emergencyContacts': emergencyContacts,
      'sosMessageText': sosMessageText,
      'includeLocation': includeLocation,
      'enableSmsFallback': enableSmsFallback,
      'sosActionMode': sosActionMode,
    };
  }

  factory FamilySosConfigModel.fromMap(Map<String, dynamic> map) {
    return FamilySosConfigModel(
      isEnabled: map['isEnabled'] as bool? ?? true,
      primaryCallNumber: map['primaryCallNumber'] as String? ?? '',
      primaryCallName: map['primaryCallName'] as String? ?? '',
      emergencyContacts: List<String>.from(map['emergencyContacts'] as List? ?? []),
      sosMessageText: map['sosMessageText'] as String? ??
          '⚠️ EMERGENCY ALERT! I am in an urgent crisis. Please reach out to me immediately!',
      includeLocation: map['includeLocation'] as bool? ?? true,
      enableSmsFallback: map['enableSmsFallback'] as bool? ?? true,
      sosActionMode: map['sosActionMode'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [
        isEnabled,
        primaryCallNumber,
        primaryCallName,
        emergencyContacts,
        sosMessageText,
        includeLocation,
        enableSmsFallback,
        sosActionMode,
      ];
}
