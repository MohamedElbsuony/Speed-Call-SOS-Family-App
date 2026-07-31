import 'package:flutter_test/flutter_test.dart';
import 'package:speed_call_app/features/calling/domain/models/family_sos_config_model.dart';

void main() {
  group('FamilySosConfigModel Tests', () {
    test('toMap and fromMap serialization works correctly', () {
      const model = FamilySosConfigModel(
        isEnabled: true,
        primaryCallNumber: '+201234567890',
        primaryCallName: 'Wife',
        emergencyContacts: ['+201234567890', '+201098765432'],
        sosMessageText: 'Custom SOS Message',
        includeLocation: true,
        enableSmsFallback: true,
        sosActionMode: 0,
      );

      final map = model.toMap();
      final fromMap = FamilySosConfigModel.fromMap(map);

      expect(fromMap, equals(model));
      expect(fromMap.primaryCallName, equals('Wife'));
      expect(fromMap.emergencyContacts.length, equals(2));
      expect(fromMap.emergencyContacts.first, equals('+201234567890'));
      expect(fromMap.sosActionMode, equals(0));
    });
  });
}
