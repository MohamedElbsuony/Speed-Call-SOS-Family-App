import 'package:equatable/equatable.dart';

enum CallType { outgoing, incoming, missed, rejected }

class CallLogModel extends Equatable {
  final String id;
  final String contactName;
  final String phoneNumber;
  final int simSlotUsed; // 0, 1
  final DateTime timestamp;
  final bool wasSuccessful;
  final CallType callType;
  final int durationSeconds;

  const CallLogModel({
    required this.id,
    required this.contactName,
    required this.phoneNumber,
    required this.simSlotUsed,
    required this.timestamp,
    required this.wasSuccessful,
    this.callType = CallType.outgoing,
    this.durationSeconds = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'contactName': contactName,
      'phoneNumber': phoneNumber,
      'simSlotUsed': simSlotUsed,
      'timestamp': timestamp.toIso8601String(),
      'wasSuccessful': wasSuccessful,
      'callType': callType.name,
      'durationSeconds': durationSeconds,
    };
  }

  factory CallLogModel.fromMap(Map<String, dynamic> map) {
    return CallLogModel(
      id: map['id'] as String,
      contactName: map['contactName'] as String,
      phoneNumber: map['phoneNumber'] as String,
      simSlotUsed: map['simSlotUsed'] as int? ?? 0,
      timestamp: DateTime.parse(map['timestamp'] as String),
      wasSuccessful: map['wasSuccessful'] as bool? ?? true,
      callType: CallType.values.firstWhere(
        (e) => e.name == map['callType'],
        orElse: () => CallType.outgoing,
      ),
      durationSeconds: map['durationSeconds'] as int? ?? 0,
    );
  }

  @override
  List<Object?> get props => [
        id,
        contactName,
        phoneNumber,
        simSlotUsed,
        timestamp,
        wasSuccessful,
        callType,
        durationSeconds,
      ];
}
