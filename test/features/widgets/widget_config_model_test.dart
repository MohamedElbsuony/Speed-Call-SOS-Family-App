import 'package:flutter_test/flutter_test.dart';
import 'package:speed_call_app/features/widgets/domain/models/widget_config_model.dart';

void main() {
  group('WidgetConfigModel Tests', () {
    final testDate = DateTime(2026, 7, 30);
    final model = WidgetConfigModel(
      id: 'test-1',
      widgetId: 101,
      contactId: 'c-1',
      contactName: 'John Doe',
      phoneNumber: '+15550192',
      simSelectionMode: 1, // SIM 1
      widgetSize: 'medium',
      imageShape: 'circular',
      backgroundColor: 0xFF1F1F2F,
      textColor: 0xFFFFFFFF,
      createdAt: testDate,
    );

    test('toMap and fromMap conversion works correctly', () {
      final map = model.toMap();
      final fromMap = WidgetConfigModel.fromMap(map);

      expect(fromMap.id, equals('test-1'));
      expect(fromMap.widgetId, equals(101));
      expect(fromMap.contactName, equals('John Doe'));
      expect(fromMap.phoneNumber, equals('+15550192'));
      expect(fromMap.simSelectionMode, equals(1));
      expect(fromMap.widgetSize, equals('medium'));
      expect(fromMap.imageShape, equals('circular'));
    });

    test('copyWith creates new object with modified values', () {
      final updated = model.copyWith(
        contactName: 'Jane Doe',
        simSelectionMode: 2,
      );

      expect(updated.contactName, equals('Jane Doe'));
      expect(updated.simSelectionMode, equals(2));
      expect(updated.id, equals(model.id));
      expect(updated.phoneNumber, equals(model.phoneNumber));
    });
  });
}
