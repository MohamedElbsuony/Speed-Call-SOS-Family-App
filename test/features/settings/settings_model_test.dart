import 'package:flutter_test/flutter_test.dart';
import 'package:speed_call_app/features/settings/domain/models/settings_model.dart';

void main() {
  group('SettingsModel Tests', () {
    const settings = SettingsModel(
      themeMode: AppThemeMode.amoled,
      enableVibration: true,
      enableCallConfirmation: false,
      languageCode: 'ar',
    );

    test('toMap and fromMap serialization works as expected', () {
      final map = settings.toMap();
      final restored = SettingsModel.fromMap(map);

      expect(restored.themeMode, equals(AppThemeMode.amoled));
      expect(restored.enableVibration, isTrue);
      expect(restored.enableCallConfirmation, isFalse);
      expect(restored.languageCode, equals('ar'));
    });
  });
}
