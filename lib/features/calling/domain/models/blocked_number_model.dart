import 'package:equatable/equatable.dart';

class BlockedNumberModel extends Equatable {
  final String id;
  final String phoneNumber;
  final String contactName;
  final String reason;
  final DateTime blockedAt;

  const BlockedNumberModel({
    required this.id,
    required this.phoneNumber,
    this.contactName = 'Unknown',
    this.reason = 'Blocked User',
    required this.blockedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'phoneNumber': phoneNumber,
      'contactName': contactName,
      'reason': reason,
      'blockedAt': blockedAt.toIso8601String(),
    };
  }

  factory BlockedNumberModel.fromMap(Map<String, dynamic> map) {
    return BlockedNumberModel(
      id: map['id'] as String,
      phoneNumber: map['phoneNumber'] as String,
      contactName: map['contactName'] as String? ?? 'Unknown',
      reason: map['reason'] as String? ?? 'Blocked User',
      blockedAt: DateTime.parse(map['blockedAt'] as String),
    );
  }

  @override
  List<Object?> get props => [id, phoneNumber, contactName, reason, blockedAt];
}
