import 'package:flutter_test/flutter_test.dart';
import 'package:speed_call_app/features/calling/domain/models/speed_dial_key_model.dart';

void main() {
  group('SpeedDialKeyModel Tests', () {
    const model = SpeedDialKeyModel(
      keyDigit: 2,
      contactId: 'c-2',
      contactName: 'Mom',
      phoneNumber: '+15550199',
      phoneLabel: 'Mobile',
    );

    test('toMap and fromMap serialization works as expected', () {
      final map = model.toMap();
      final restored = SpeedDialKeyModel.fromMap(map);

      expect(restored.keyDigit, equals(2));
      expect(restored.contactName, equals('Mom'));
      expect(restored.phoneNumber, equals('+15550199'));
      expect(restored.phoneLabel, equals('Mobile'));
    });
  });
}
