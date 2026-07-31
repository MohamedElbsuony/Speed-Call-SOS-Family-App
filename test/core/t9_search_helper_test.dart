import 'package:flutter_test/flutter_test.dart';
import 'package:speed_call_app/core/utils/t9_search_helper.dart';
import 'package:speed_call_app/features/contacts/domain/models/contact_model.dart';

void main() {
  group('T9SearchHelper Tests', () {
    test('nameToT9Digits converts names to T9 keypad numbers correctly', () {
      expect(T9SearchHelper.nameToT9Digits('Mom'), equals('666'));
      expect(T9SearchHelper.nameToT9Digits('Alex'), equals('2539'));
    });

    test('filterContactsByT9 matches entered digits against contacts', () {
      const contacts = [
        ContactModel(
          id: '1',
          displayName: 'Mom',
          phones: [PhoneEntry(number: '+15550199', label: 'Mobile')],
        ),
        ContactModel(
          id: '2',
          displayName: 'Alex',
          phones: [PhoneEntry(number: '+15550122', label: 'Work')],
        ),
      ];

      final momMatches = T9SearchHelper.filterContactsByT9(contacts, '666');
      expect(momMatches.length, equals(1));
      expect(momMatches.first.displayName, equals('Mom'));

      final alexMatches = T9SearchHelper.filterContactsByT9(contacts, '253');
      expect(alexMatches.length, equals(1));
      expect(alexMatches.first.displayName, equals('Alex'));
    });
  });
}
