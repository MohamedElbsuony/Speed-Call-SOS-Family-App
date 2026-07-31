import 'package:equatable/equatable.dart';

class SpeedDialKeyModel extends Equatable {
  final int keyDigit; // 1 to 9
  final String contactId;
  final String contactName;
  final String phoneNumber;
  final String phoneLabel;
  final String photoPath;
  final int simSelectionMode; // 0: Default, 1: SIM 1, 2: SIM 2, 3: Ask

  const SpeedDialKeyModel({
    required this.keyDigit,
    required this.contactId,
    required this.contactName,
    required this.phoneNumber,
    this.phoneLabel = 'Mobile',
    this.photoPath = '',
    this.simSelectionMode = 0,
  });

  SpeedDialKeyModel copyWith({
    int? keyDigit,
    String? contactId,
    String? contactName,
    String? phoneNumber,
    String? phoneLabel,
    String? photoPath,
    int? simSelectionMode,
  }) {
    return SpeedDialKeyModel(
      keyDigit: keyDigit ?? this.keyDigit,
      contactId: contactId ?? this.contactId,
      contactName: contactName ?? this.contactName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      phoneLabel: phoneLabel ?? this.phoneLabel,
      photoPath: photoPath ?? this.photoPath,
      simSelectionMode: simSelectionMode ?? this.simSelectionMode,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'keyDigit': keyDigit,
      'contactId': contactId,
      'contactName': contactName,
      'phoneNumber': phoneNumber,
      'phoneLabel': phoneLabel,
      'photoPath': photoPath,
      'simSelectionMode': simSelectionMode,
    };
  }

  factory SpeedDialKeyModel.fromMap(Map<String, dynamic> map) {
    return SpeedDialKeyModel(
      keyDigit: map['keyDigit'] as int,
      contactId: map['contactId'] as String? ?? '',
      contactName: map['contactName'] as String? ?? '',
      phoneNumber: map['phoneNumber'] as String? ?? '',
      phoneLabel: map['phoneLabel'] as String? ?? 'Mobile',
      photoPath: map['photoPath'] as String? ?? '',
      simSelectionMode: map['simSelectionMode'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [
        keyDigit,
        contactId,
        contactName,
        phoneNumber,
        phoneLabel,
        photoPath,
        simSelectionMode,
      ];
}
