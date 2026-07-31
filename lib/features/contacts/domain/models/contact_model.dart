import 'package:equatable/equatable.dart';

class PhoneEntry extends Equatable {
  final String number;
  final String label; // Mobile, Work, Home, Main, Other

  const PhoneEntry({
    required this.number,
    required this.label,
  });

  @override
  List<Object?> get props => [number, label];
}

class ContactModel extends Equatable {
  final String id;
  final String displayName;
  final List<PhoneEntry> phones;
  final String photoPath;
  final bool isPinned;
  final bool isFavorite;

  const ContactModel({
    required this.id,
    required this.displayName,
    required this.phones,
    this.photoPath = '',
    this.isPinned = false,
    this.isFavorite = false,
  });

  ContactModel copyWith({
    String? id,
    String? displayName,
    List<PhoneEntry>? phones,
    String? photoPath,
    bool? isPinned,
    bool? isFavorite,
  }) {
    return ContactModel(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      phones: phones ?? this.phones,
      photoPath: photoPath ?? this.photoPath,
      isPinned: isPinned ?? this.isPinned,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  @override
  List<Object?> get props => [id, displayName, phones, photoPath, isPinned, isFavorite];
}
