import 'package:equatable/equatable.dart';

enum AppThemeMode { light, dark, amoled, system }

class SettingsModel extends Equatable {
  final AppThemeMode themeMode;
  final bool enableVibration;
  final bool enableCallConfirmation;
  final String languageCode; // 'en', 'ar'
  final bool useDynamicColors;

  const SettingsModel({
    this.themeMode = AppThemeMode.system,
    this.enableVibration = true,
    this.enableCallConfirmation = false,
    this.languageCode = 'en',
    this.useDynamicColors = true,
  });

  SettingsModel copyWith({
    AppThemeMode? themeMode,
    bool? enableVibration,
    bool? enableCallConfirmation,
    String? languageCode,
    bool? useDynamicColors,
  }) {
    return SettingsModel(
      themeMode: themeMode ?? this.themeMode,
      enableVibration: enableVibration ?? this.enableVibration,
      enableCallConfirmation: enableCallConfirmation ?? this.enableCallConfirmation,
      languageCode: languageCode ?? this.languageCode,
      useDynamicColors: useDynamicColors ?? this.useDynamicColors,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'themeMode': themeMode.name,
      'enableVibration': enableVibration,
      'enableCallConfirmation': enableCallConfirmation,
      'languageCode': languageCode,
      'useDynamicColors': useDynamicColors,
    };
  }

  factory SettingsModel.fromMap(Map<String, dynamic> map) {
    return SettingsModel(
      themeMode: AppThemeMode.values.firstWhere(
        (e) => e.name == map['themeMode'],
        orElse: () => AppThemeMode.system,
      ),
      enableVibration: map['enableVibration'] as bool? ?? true,
      enableCallConfirmation: map['enableCallConfirmation'] as bool? ?? false,
      languageCode: map['languageCode'] as String? ?? 'en',
      useDynamicColors: map['useDynamicColors'] as bool? ?? true,
    );
  }

  @override
  List<Object?> get props => [
        themeMode,
        enableVibration,
        enableCallConfirmation,
        languageCode,
        useDynamicColors,
      ];
}
