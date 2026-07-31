import 'package:equatable/equatable.dart';

class WidgetConfigModel extends Equatable {
  final String id;
  final int widgetId; // Android AppWidget ID
  final String contactId;
  final String contactName;
  final String phoneNumber;
  final String phoneLabel; // Mobile, Work, Home, Other
  final String photoPath;
  final int simSelectionMode; // 0: Default, 1: SIM 1, 2: SIM 2, 3: Ask Every Time
  final String widgetSize; // small, medium, large
  final String imageShape; // circular, rounded, square
  final int backgroundColor; // ARGB int
  final int textColor; // ARGB int
  final bool isTransparent;
  final double opacity;
  final double borderRadius;
  final bool showName;
  final bool showPhone;
  final DateTime createdAt;

  const WidgetConfigModel({
    required this.id,
    required this.widgetId,
    required this.contactId,
    required this.contactName,
    required this.phoneNumber,
    this.phoneLabel = 'Mobile',
    this.photoPath = '',
    this.simSelectionMode = 0,
    this.widgetSize = 'small',
    this.imageShape = 'circular',
    this.backgroundColor = 0xFF1F1F2F,
    this.textColor = 0xFFFFFFFF,
    this.isTransparent = false,
    this.opacity = 1.0,
    this.borderRadius = 16.0,
    this.showName = true,
    this.showPhone = true,
    required this.createdAt,
  });

  WidgetConfigModel copyWith({
    String? id,
    int? widgetId,
    String? contactId,
    String? contactName,
    String? phoneNumber,
    String? phoneLabel,
    String? photoPath,
    int? simSelectionMode,
    String? widgetSize,
    String? imageShape,
    int? backgroundColor,
    int? textColor,
    bool? isTransparent,
    double? opacity,
    double? borderRadius,
    bool? showName,
    bool? showPhone,
    DateTime? createdAt,
  }) {
    return WidgetConfigModel(
      id: id ?? this.id,
      widgetId: widgetId ?? this.widgetId,
      contactId: contactId ?? this.contactId,
      contactName: contactName ?? this.contactName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      phoneLabel: phoneLabel ?? this.phoneLabel,
      photoPath: photoPath ?? this.photoPath,
      simSelectionMode: simSelectionMode ?? this.simSelectionMode,
      widgetSize: widgetSize ?? this.widgetSize,
      imageShape: imageShape ?? this.imageShape,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textColor: textColor ?? this.textColor,
      isTransparent: isTransparent ?? this.isTransparent,
      opacity: opacity ?? this.opacity,
      borderRadius: borderRadius ?? this.borderRadius,
      showName: showName ?? this.showName,
      showPhone: showPhone ?? this.showPhone,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'widgetId': widgetId,
      'contactId': contactId,
      'contactName': contactName,
      'phoneNumber': phoneNumber,
      'phoneLabel': phoneLabel,
      'photoPath': photoPath,
      'simSelectionMode': simSelectionMode,
      'widgetSize': widgetSize,
      'imageShape': imageShape,
      'backgroundColor': backgroundColor,
      'textColor': textColor,
      'isTransparent': isTransparent,
      'opacity': opacity,
      'borderRadius': borderRadius,
      'showName': showName,
      'showPhone': showPhone,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory WidgetConfigModel.fromMap(Map<String, dynamic> map) {
    return WidgetConfigModel(
      id: map['id'] as String,
      widgetId: map['widgetId'] as int? ?? -1,
      contactId: map['contactId'] as String? ?? '',
      contactName: map['contactName'] as String? ?? 'Speed Call',
      phoneNumber: map['phoneNumber'] as String? ?? '',
      phoneLabel: map['phoneLabel'] as String? ?? 'Mobile',
      photoPath: map['photoPath'] as String? ?? '',
      simSelectionMode: map['simSelectionMode'] as int? ?? 0,
      widgetSize: map['widgetSize'] as String? ?? 'small',
      imageShape: map['imageShape'] as String? ?? 'circular',
      backgroundColor: map['backgroundColor'] as int? ?? 0xFF1F1F2F,
      textColor: map['textColor'] as int? ?? 0xFFFFFFFF,
      isTransparent: map['isTransparent'] as bool? ?? false,
      opacity: (map['opacity'] as num?)?.toDouble() ?? 1.0,
      borderRadius: (map['borderRadius'] as num?)?.toDouble() ?? 16.0,
      showName: map['showName'] as bool? ?? true,
      showPhone: map['showPhone'] as bool? ?? true,
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  @override
  List<Object?> get props => [
        id,
        widgetId,
        contactId,
        contactName,
        phoneNumber,
        phoneLabel,
        photoPath,
        simSelectionMode,
        widgetSize,
        imageShape,
        backgroundColor,
        textColor,
        isTransparent,
        opacity,
        borderRadius,
        showName,
        showPhone,
        createdAt,
      ];
}
